std = "lua51"
max_line_length = 80

include_files = {
    ".busted",
    ".luacheckrc",
    ".luacov",
    "*.rockspec",
    "rockspecs/*.rockspec",
    "spec/*.lua",
    "src/*.lua",
}

files[".luacheckrc"].std = "+luacheckrc"
files["*.rockspec"].std = "+rockspec"
files["rockspecs/*.rockspec"].std = "+rockspec"
files["spec/**/*.lua"].std = "+busted"
