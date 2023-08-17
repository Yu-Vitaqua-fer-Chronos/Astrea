import std/[
  asyncdispatch,
  monotimes,
  options,
  random,
  tables,
  times
]

import dimscord
import dimscmd

import ./[
  helpers,
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

        if (cuId in data.blacklist) and (m.channel_id notin data.whitelist):
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


proc canUseCommand(i: Interaction, channel: Option[GuildChannel]): Future[bool] {.async.} =
  result = true

  var c: GuildChannel

  if channel.isSome:
    c = channel.get()

  else:
    if not i.channel_id.isSome:
      await astrea.api.sendInteractionMessage(i, "*How did you get here?*")

    let cchannel = (await astrea.api.getChannel(i.channel_id.get()))[0]

    if cchannel.isSome:
      c = cchannel.get()

    else:
      await astrea.api.sendInteractionMessage(i, "You can't use this command here!")
      return false

  let userPerms = computePerms(
    astrea.api.getGuild(c.guild_id).await,
    i.member.get(),
    c
  )

  if (not userPerms.hasPerms(permManageChannels, permMentionEveryone,
    permManageMessages)) and (not userPerms.hasPerms(permAdministrator)):
    await astrea.api.sendInteractionMessage(i, "You can't use this command due to insufficient privileges!")
    return false


cmd.addSlash("dm whitelist add") do (channel: Option[GuildChannel]):
  ## Whitelists a channel for pinging
  if canUseCommand(i, channel).await:
    let c = channel.get()

    if c.id in data.blacklist:
      await astrea.api.sendInteractionMessage(i, "This channel was explicitly blacklisted! Please unblacklist it first!")
      return

    if c.id notin data.whitelist:
      data.whitelist.add c.id

    await astrea.api.sendInteractionMessage(i, "Channel added to whitelist!")
    await data.save()

cmd.addSlash("dm blacklist add") do (channel: Option[GuildChannel]):
  ## Blacklists a channel for pinging
  if canUseCommand(i, channel).await:
    let c = channel.get()

    if c.id in data.whitelist:
      await astrea.api.sendInteractionMessage(i, "This channel was explicitly whitelisted! Please unwhitelist it first!")
      return

    if c.id notin data.blacklist:
      data.blacklist.add c.id

    await astrea.api.sendInteractionMessage(i, "Channel added to blacklist!!")
    await data.save()

cmd.addSlash("dm whitelist rm") do (channel: Option[GuildChannel]):
  ## Unwhitelists a channel for pinging
  if canUseCommand(i, channel).await:
    let
      c = channel.get()
      loc = data.whitelist.find c.id

    if loc == -1:
      await astrea.api.sendInteractionMessage(i, "Can't remove something that was never in the whitelist!")
      return

    data.whitelist.delete(loc)
    await astrea.api.sendInteractionMessage(i, "Channel removed from the whitelist!")
    await data.save()

cmd.addSlash("dm blacklist rm") do (channel: Option[GuildChannel]):
  ## Unblacklists a channel for pinging
  if canUseCommand(i, channel).await:
    let
      c = channel.get()
      loc = data.blacklist.find c.id

    if loc == -1:
      await astrea.api.sendInteractionMessage(i, "Can't remove something that was never in the blacklist!")
      return

    data.blacklist.delete(loc)
    await astrea.api.sendInteractionMessage(i, "Channel removed from the blacklist!")
    await data.save()
