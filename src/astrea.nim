import std/[
  asyncdispatch,
  monotimes,
  options,
  random,
  tables,
  times,
  json
]

randomize()

import dimscord

let lowMt = getMonoTime() - initDuration(minutes=5)

type
  Config = object
    token: string
    randomPrompts: bool = true

  Data = object
    prompts: seq[string] = newSeq[string](0)
    blacklist: seq[string] = newSeq[string](0)

var
  data = readFile("data.json").parseJson().to(Data)
  channelCooldown: Table[string, MonoTime]

let
  config = readFile("config.json").parseJson().to(Config)
  astrea = newDiscordClient(config.token)

proc onReady(s: Shard, r: Ready) {.event(astrea).} =
  echo "Astrea Shadowstar, reporting for duty!"

proc messageCreate(s: Shard, m: Message) {.event(astrea).} =
  if m.author.bot:
    return

  let cs = (await astrea.api.getChannel(m.channel_id))[0]

  let c: GuildChannel = if cs.isSome:
    cs.get()
  else:
    return

  if c.id in data.blacklist:
    return

  elif c.parent_id.isSome:
    if c.parent_id.get() in data.blacklist:
      return

  if (getMonoTime() - channelCooldown.getOrDefault(c.id, lowMt)).inMinutes >= 5:
    var msg: Message

    if config.randomPrompts:
      msg = await astrea.api.sendMessage(c.id, "@everyone\n" & data.prompts.sample())
    else:
      msg = await astrea.api.sendMessage(c.id, "@everyone")

    await astrea.api.deleteMessage(c.id, msg.id)

    channelCooldown[c.id] = getMonoTime()

  else:
    channelCooldown[c.id] = getMonoTime()


waitFor astrea.startSession()
