#!/usr/bin/env bash
#
# Find a LuaRocks rockspec based on inputs and workflow context.

set -euo pipefail

# Directories searched by LuaRocks
readonly SEARCH_DIRS=(. rockspec rockspecs)

die() {
    printf '::error::%s\n' "$*" >&2
    exit 1
}

debug() {
    printf '::debug::%s\n' "$*"
}

notice() {
    printf '::notice::%s\n' "$*"
}

# Safe filename
is_valid_input() {
    [[ "$1" =~ ^[[:alnum:]._-]+$ ]]
}

# SemVer without build metadata
is_valid_semver() {
    local regex
    regex='^(0|[1-9][0-9]*)'          # major version
    regex+='(\.(0|[1-9][0-9]*)){0,2}' # optional major and minor versions
    regex+='(-[0-9A-Za-z.-]+)?$'      # optional pre-release version
    [[ "$1" =~ $regex ]]
}

# Non-negative integer
is_valid_revision() {
    [[ "$1" =~ ^(0|[1-9][0-9]*)$ ]]
}

# Normalize SemVer for use in a rockspec version.
#
# Rockspec version has the form:
#   <version>-<revision>
#
# As of 3.8.0, `luarocks new_version` strips hyphens from the version component
# to avoid ambiguity with the revision separator.
# The final rockspec version must match the Lua pattern:
#   [%w.]+-[%d]+
#
# Because hyphens cannot be preserved or encoded as underscores, the only
# viable option is to remove them.
normalize_version() {
    local original=$1 normalized=${1//-/}
    [[ "$normalized" == "$original" ]] ||
        notice "Normalized version '$original' to '$normalized'."
    printf '%s\n' "$normalized"
}

main() {
    # Resolve rockspec metadata

    local package=${INPUT_PACKAGE:-}

    if [[ -z "$package" ]]; then
        package=${GITHUB_REPOSITORY:?}
        package=${package#*/}
        notice "No package provided, using repository name: $package"
    fi

    is_valid_input "$package" || die "Invalid package: $package"

    local version revision

    if [[ -n "${INPUT_VERSION:-}" ]]; then
        version=$INPUT_VERSION
        revision=${INPUT_REVISION:-}
    else
        [[ "${GITHUB_REF_TYPE:?}" == tag ]] ||
            die "Workflow was not triggered from a tag."

        local tag=${GITHUB_REF_NAME:?}
        version=${tag#v}
        revision=""

        [[ "$version" == *"+"* ]] && {
            revision=${version#*+} # SemVer build metadata
            version=${version%+"$revision"}
        }

        debug "Parsed tag '$tag': version='$version' revision='$revision'"

        is_valid_semver "$version" || die "Invalid SemVer version: $version"
    fi

    is_valid_input "$version" || die "Invalid version: $version"

    { [[ -z "$revision" ]] || is_valid_revision "$revision"; } ||
        die "Invalid revision: $revision"

    version=$(normalize_version "$version")

    # Find rockspec

    [[ -n "$revision" ]] ||
        debug "No revision specified, selecting highest available."

    local dir candidate candidate_rev rockspec="" max_rev=-1

    for dir in "${SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue

        for candidate in "$dir/$package-$version-"*.rockspec; do
            [[ -e "$candidate" ]] || continue

            candidate_rev=${candidate##*/}
            candidate_rev=${candidate_rev%.rockspec}
            candidate_rev=${candidate_rev##*-}

            is_valid_revision "$candidate_rev" || {
                debug "Ignoring: $candidate" \
                    "(invalid revision '$candidate_rev')"
                continue
            }

            if [[ -n "$revision" ]]; then
                # Select exact revision
                if (( candidate_rev == revision )); then
                    debug "Matched exact revision: $candidate_rev"
                    rockspec=$candidate
                    break 2 # break candidate and directory loops
                fi
            elif (( candidate_rev > max_rev )); then
                # Select highest revision
                debug "Selecting revision: $candidate_rev"
                rockspec=$candidate
                max_rev=$candidate_rev
            fi
        done
    done

    [[ -n "$rockspec" ]] ||
        die "Rockspec not found: $package-$version-${revision:-*}.rockspec"

    [[ -n "$revision" ]] || {
        revision=$max_rev
        notice "Selected highest available revision: $revision"
    }

    # Write outputs

    {
        printf 'rockspec_package=%s\n' "$package"
        printf 'rockspec_version=%s\n' "$version"
        printf 'rockspec_revision=%s\n' "$revision"
        printf 'rockspec_path=%s\n' "$rockspec"
    } >>"${GITHUB_OUTPUT:?}"
}

main "$@"
