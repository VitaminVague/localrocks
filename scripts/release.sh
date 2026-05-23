#!/usr/bin/env bash
#
# Release workflow for LuaRocks rockspecs.

set -euo pipefail

# TODO: Load configuration from file.
readonly DEFAULT_BRANCH=master
readonly PACKAGE=localrocks
readonly RELEASE_DIR=rockspecs
# As of 3.8.0, `luarocks new_version` insists the source rockspec lives in cwd
readonly SOURCE_DIR=.
readonly SOURCE_VERSION=scm
readonly SOURCE_REVISION=1

usage() {
    cat >&2 <<END
Usage: $0 <version> [revision]

Examples:
  $0 1.2.3
  $0 1.2.3 2
  $0 1.2.3-rc.1
END
    exit 1
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

# SemVer without build metadata
is_valid_version() {
    local regex
    regex='^(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*)){2}' # version core
    regex+='(-[0-9A-Za-z.-]+)?$' # pre-release
    [[ "$1" =~ $regex ]]
}

# Positive integer
is_valid_revision() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

ensure_git_root() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) ||
        die "Not a Git repository."
    cd "$root"
}

ensure_clean_working_tree() {
    { git diff --quiet && git diff --cached --quiet; } || {
        git status --short >&2
        die "Working tree has uncommitted changes."
    }

    local untracked
    untracked=$(git ls-files --others --exclude-standard)

    [[ -z "$untracked" ]] || {
        echo "$untracked" >&2
        die "Working tree has untracked files."
    }
}

ensure_default_branch() {
    local branch
    branch=$(git branch --show-current)

    [[ "$branch" == "$DEFAULT_BRANCH" ]] ||
        die "Must be on '$DEFAULT_BRANCH' branch" \
            "(current: ${branch:-detached HEAD})."
}

ensure_upstream_sync() {
    git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &>/dev/null ||
        die "Local branch has no upstream configured."

    git fetch --quiet --prune --tags

    [[ "$(git rev-parse @)" == "$(git rev-parse '@{u}')" ]] && return 0

    git merge-base --is-ancestor '@{u}' @ &&
        die "Local branch is ahead of upstream."

    git merge-base --is-ancestor @ '@{u}' &&
        die "Local branch is behind upstream."

    die "Local and upstream branches have diverged."
}

tag_exists() {
    git rev-parse --verify --quiet "refs/tags/$1" >/dev/null
}

tag_name() {
    local version=$1 revision=$2
    local tag="v$version"
    (( revision > 1 )) && tag+="+$revision" # SemVer build metadata
    printf '%s\n' "$tag"
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
to_rockspec_version() {
    local version=${1//-/} revision=$2
    printf '%s-%s\n' "$version" "$revision"
}

rockspec_path() {
    local dir=$1 package=$2 rockspec_version=$3
    if [[ -z "$dir" || "$dir" == "." ]]; then
        printf '%s-%s.rockspec\n' "$package" "$rockspec_version"
    else
        printf '%s/%s-%s.rockspec\n' "$dir" "$package" "$rockspec_version"
    fi
}

confirm_release() {
    local tag=$1 rockspec=$2
    cat <<END

About to do the following:
1. Create rockspec: $rockspec
2. Commit release
3. Create tag: $tag

END
    read -rp "Continue? (y/N) "
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

main() {
    # Parse args

    (( $# >= 1 && $# <= 2 )) || usage

    local version=$1 revision=${2:-1}

    is_valid_version "$version" ||
        die "Invalid version: $version (expected: 1.2.3, 1.2.3-rc.1)"

    is_valid_revision "$revision" ||
        die "Invalid revision: $revision (expected positive integer)"

    # Validate environment

    ensure_git_root
    ensure_clean_working_tree
    ensure_default_branch
    ensure_upstream_sync

    # Compute release metadata

    local tag
    tag=$(tag_name "$version" "$revision")

    tag_exists "$tag" && die "Tag already exists: $tag"

    local rockspec_version release_rockspec
    rockspec_version=$(to_rockspec_version "$version" "$revision")
    release_rockspec=$(rockspec_path \
        "$RELEASE_DIR" "$PACKAGE" "$rockspec_version")

    [[ -e "$release_rockspec" ]] &&
        die "Rockspec already exists: $release_rockspec"

    confirm_release "$tag" "$release_rockspec" || {
        echo "Aborted." >&2
        exit 1
    }

    local source_rockspec_version source_rockspec
    source_rockspec_version=$(to_rockspec_version \
        "$SOURCE_VERSION" "$SOURCE_REVISION")
    source_rockspec=$(rockspec_path \
        "$SOURCE_DIR" "$PACKAGE" "$source_rockspec_version")

    # Perform release

    # 1. Create rockspec

    echo "Creating rockspec"

    local flags=(--tag "$tag")

    [[ -n "$RELEASE_DIR" ]] && {
        mkdir -p "$RELEASE_DIR"
        flags+=(--dir "$RELEASE_DIR")
    }

    luarocks new_version "${flags[@]}" "$source_rockspec" "$rockspec_version"

    [[ -f "$release_rockspec" ]] ||
        die "Rockspec was not created: $release_rockspec"

    # 2. Commit release

    echo "Committing changes"

    git add "$release_rockspec" &&
    git commit -m "Release $tag"

    # 3. Create tag

    echo "Creating tag"

    git tag -a -m "Release $tag" "$tag"

    # Print success

    cat << END

Release $tag prepared successfully!

Next steps:
  git push origin $DEFAULT_BRANCH
  git push origin $tag
END
}

main "$@"
