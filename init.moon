-- MIT License
-- Copyright (c) 2019 Martín Aguilar

class VM
   new: (options = { module: false }) =>
      @options = options
      @env = {}

{ :VM }
