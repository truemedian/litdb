return {
  -- Export main class
  Core = require('Core'),
  -- Export plugin,
  Plugin = require('plugins/Plugin'),
  SourcePlugin = require('plugins/SourcePlugin'),
  -- Export player related class
  AudioFilter = require('player/AudioFilter'),
  Player = require('player/Player'),
  Queue = require('player/Queue'),
  Track = require('player/Track'),
  Voice = require('player/Voice'),
  -- Export node related class
  Node = require('node/Node'),
  PlayerEvents = require('node/PlayerEvents'),
  Rest = require('node/Rest'),
  -- Export manager class
  NodeManager = require('manager/NodeManager'),
  PlayerManager = require('manager/PlayerManager'),
  -- Export library class
  AbstractLibrary = require('library/AbstractLibrary'),
  library = require('library'),
  -- Export driver
  AbstractDriver = require('drivers/AbstractDriver'),
  driver = require('drivers'),
  -- Export utils
  Cache = require('utils/Cache'),
  Emitter = require('utils/Emitter'),
  Functions = require('utils/Functions'),
  WebSocket = require('utils/WebSocket'),
  -- Export miscs
  constants = require('const'),
  enums = require('enums'),
  manifest = require('manifest'),
  class = require('class'),
}
