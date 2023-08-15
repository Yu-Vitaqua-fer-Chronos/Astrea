import std/[
  asyncdispatch,
  monotimes,
  tables,
  json
]

import dimscord
import dimscmd

import ./[
  types
]

let
  config* = parseFile("config.json").to(Config)
  astrea* = newDiscordClient(config.token)

var
  dataLocked = false
  data* = parseFile("data.json").to(Data)
  channelCooldown*: Table[string, MonoTime]
  cmd* = astrea.newHandler()

proc save(d: Data) {.async.} =
  while dataLocked:
    await sleepAsync(1000)

  dataLocked = true

  writeFile("data.json", pretty(%*d))

  dataLocked = false

waitFor save(data)
