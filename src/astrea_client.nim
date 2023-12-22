import std/[
  asyncdispatch,
  options,
  random
]

import dimscord
import dimscmd

import ./[
  dmlogic,
  shared,
  types
]

randomize()

proc onReady(s: Shard, r: Ready) {.event(astrea).} =
  echo "Astrea Shadowstar, reporting for duty!"

  await cmd.registerCommands()
  shared.astreaId = astrea.shards.values().toSeq().sample().user.id

  var status: string

  while true:
    status = "online"

    if s.latency >= 425:
      if s.latency <= 700:
        status = "idle"

      elif s.latency > 700:
        status = "dnd"

    asyncCheck s.updateStatus(sample(data.activities).some, status)

    await sleepAsync 15000

proc messageCreate(s: Shard, m: Message) {.event(astrea).} =
  await dmHandler(s, m)

proc interactionCreate(s: Shard, i: Interaction) {.event(astrea).} =
    discard await cmd.handleInteraction(s, i)

waitFor astrea.startSession(
  gateway_intents={giGuilds, giGuildMessages, giMessageContent},
  cache_users=false, cache_guilds=false, guild_subscriptions=false,
  cache_guild_channels=false, cache_dm_channels=false
)
