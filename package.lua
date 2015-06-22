return {
  name = "gsick/uuid",
  version = "1.0.0",
  description = "UUID generator",
  tags = {
    "uuid"
  },
  author = {
    name = "Rackspace"
  },
  contributors = {
    "Thijs Schreijer",
    "Gamaliel Sick"
  },
  homepage = "https://github.com/gsick/lit-uuid",
  dependencies = {
    "gsick/clocktime@1.0.0",
    "gsick/redis@0.0.1"
  },
  files = {
    "*.lua",
    "!tests",
    "!examples"
  }
}
