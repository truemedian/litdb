  return {
    name = "alphafantomu/mime-types",
    version = "0.0.2",
    description = "lua content-type utility",
    tags = { "lua", "luvit" },
    license = "MIT",
    author = { name = "Ari Kumikaeru", email = "phantomcrazyheart@gmail.com" },
    homepage = "https://github.com/alphafantomu/mime-types",
    dependencies = {
			'alphafantomu/mime-db';
		},
    files = {
      "**.lua",
			"!test*"
    }
  }
  