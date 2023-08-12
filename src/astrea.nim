import std/[
  asyncdispatch,
  monotimes,
  #strutils,
  options,
  random,
  tables,
  times,
  json
]

import dimscord

import ./[
  shared,
  types
]

randomize()

let lowMt = getMonoTime() - initDuration(minutes=5)

var
  data = readFile("data.json").parseJson().to(Data)
  channelCooldown: Table[string, MonoTime]

let
  config = readFile("config.json").parseJson().to(Config)
  astrea = newDiscordClient(config.token)

proc onReady(s: Shard, r: Ready) {.event(astrea).} =
  echo "Astrea Shadowstar, reporting for duty!"

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
  if m.author.bot:
    return

  var cuId = m.channel_id

  if cuId in data.blacklist:
    return

  while cuId notin data.whitelist:
    let mc = (await astrea.api.getChannel(cuId))[0]

    if mc.isSome:
      if mc.get().parent_id.isSome:
        cuId = mc.get().parent_id.get()

        if cuId in data.blacklist:
          return

      else:
        return

  if (getMonoTime() - channelCooldown.getOrDefault(m.channel_id, lowMt)).inMinutes >= 5:
    channelCooldown[m.channel_id] = getMonoTime()

    var msg: Message

    if config.randomPrompts:
      msg = await astrea.api.sendMessage(m.channel_id, "@everyone\n" & data.prompts.sample())
    else:
      msg = await astrea.api.sendMessage(m.channel_id, "@everyone")

    await astrea.api.deleteMessage(msg.channel_id, msg.id)

  else:
    channelCooldown[m.channel_id] = getMonoTime()


waitFor astrea.startSession(
  gateway_intents={giGuilds, giGuildMessages, giMessageContent},
  cache_users=false, cache_guilds=false, guild_subscriptions=false,
  cache_guild_channels=false, cache_dm_channels=false
)
