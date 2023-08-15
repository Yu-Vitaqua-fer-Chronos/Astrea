import std/[
  asyncdispatch,
  monotimes,
  options,
  times,
]

import dimscord

import ./[
  constants,
  shared,
  types
]

#cmd.addSlash("chat link", guildID=DefaultGuildID) do (freq: string, c: GuildChannel):
#  if 

proc bridgeHandler*(s: Shard, m: Message) {.async.} =
  discard
