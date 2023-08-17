import std/[
  asyncdispatch,
  monotimes,
  tables,
  json
]

import dimscord
import dimscmd

import ./[
  constants,
  types
]

template loadJsonFile(s: string): JsonNode =
  try:
    parseFile(s)
  except JsonParsingError as err:
    raise newException(JsonParsingError, "There was an error parsing `" &
      s & "`! Check the JSON file to fix the error!", err)

let
  config* = loadJsonFile("config.json").to(Config)
  astrea* = newDiscordClient(config.token)

var
  dataLocked = false
  data* = loadJsonFile("data.json").to(Data)
  channelCooldown*: Table[string, MonoTime]
  cmd* = astrea.newHandler(defaultGuildID=DefaultGuildID)

proc save*(d: Data) {.async.} =
  while dataLocked:
    await sleepAsync(1000)

  dataLocked = true

  writeFile("data.json", pretty(%*d))

  dataLocked = false
