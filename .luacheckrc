std = "lua51"
max_line_length = 80

include_files = {
    ".busted",
    ".luacheckrc",
    ".luacov",
    "rockspecs/*.rockspec",
    "spec/*.lua",
    "src/*.lua",
}

files[".luacheckrc"].std = "+luacheckrc"
files["rockspecs/*.rockspec"].std = "+rockspec"
files["spec/**/*.lua"].std = "+busted"
