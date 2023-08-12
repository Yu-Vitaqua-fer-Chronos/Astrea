import std/[
  monotimes,
  tables,
  json
]

import dimscord

import ./[
  types
]

var
  data* = readFile("data.json").parseJson().to(Data)
  channelCooldown*: Table[string, MonoTime]

let
  config* = readFile("config.json").parseJson().to(Config)
  astrea* = newDiscordClient(config.token)
