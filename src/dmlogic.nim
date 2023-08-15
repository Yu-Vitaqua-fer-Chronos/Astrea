import std/[
  asyncdispatch,
  monotimes,
  options,
  random,
  tables,
  times
]

import dimscord

import ./[
  shared,
  types
]


let lowMt = getMonoTime() - initDuration(minutes=5)

proc dmHandler*(s: Shard, m: Message) {.async.} =
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


#cmd.addSlash("dm whitelist", guildID=DefaultGuildID) do (c: Channel):
