return {
    name = "dustin10weering/luvit-yt-searcher",
    version = "1.0",
    homepage = "https://github.com/dustin10weering/luvit-yt-searcher",
    dependencies = {
		'creationix/coro-http@3.1.0'
	},
    description = "Uses youtube api from google to search youtube videos.",
    tags = {
        "yt",
        "searcher",
        "luvit",
	    "youtube",
	    "search"
    },
    license = "MIT",
    author = "dustin10weering",
    files = {
        "*.lua",
        "!ytsearcher.lua"
    }
}