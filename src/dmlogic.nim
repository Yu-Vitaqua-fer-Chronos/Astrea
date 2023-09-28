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


let
  defaultDuration = initDuration(minutes=5)
  lowMt = getMonoTime() - defaultDuration

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

  if (getMonoTime() - channelCooldown.getOrDefault(m.channel_id, lowMt)) >= data.customCooldowns.getOrDefault(m.channel_id, defaultDuration):
    channelCooldown[m.channel_id] = getMonoTime()

    var msg: Message

    if config.randomPrompts:
      msg = await astrea.api.sendMessage(m.channel_id, "@everyone\n" & data.prompts.sample())
    else:
      msg = await astrea.api.sendMessage(m.channel_id, "@everyone")

    await astrea.api.deleteMessage(msg.channel_id, msg.id)

  else:
    channelCooldown[m.channel_id] = getMonoTime()

proc isWhitelisted(c: GuildChannel): Future[bool] {.async.} =
  result = true

  var cuId = c.id

  if cuId in data.blacklist:
    return

  while cuId notin data.whitelist:
    let mc = (await astrea.api.getChannel(cuId))[0]

    if mc.isSome:
      if mc.get().parent_id.isSome:
        cuId = mc.get().parent_id.get()

        if (cuId in data.blacklist) and (c.id notin data.whitelist):
          return false

      else:
        return false

proc canUseCommand(i: Interaction, channel: Option[GuildChannel]): Future[bool] {.async.} =
  result = true

  var c: GuildChannel

  if channel.isSome:
    c = channel.get()

  else:
    if not i.channel_id.isSome:
      await astrea.api.sendInteractionMessage(i, "*How did you get here?*")
      return false

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
    let c = channel.get (await astrea.api.getChannel(i.channel_id.get()))[0].get()

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
    let c = channel.get (await astrea.api.getChannel(i.channel_id.get()))[0].get()

    if c.id in data.whitelist:
      await astrea.api.sendInteractionMessage(i, "This channel was explicitly whitelisted! Please unwhitelist it first!")
      return

    if c.id notin data.blacklist:
      data.blacklist.add c.id

    await astrea.api.sendInteractionMessage(i, "Channel added to blacklist!!")
    await data.save()

cmd.addSlash("dm whitelist remove") do (channel: Option[GuildChannel]):
  ## Unwhitelists a channel for pinging
  if canUseCommand(i, channel).await:
    let
      c = channel.get (await astrea.api.getChannel(i.channel_id.get()))[0].get()
      loc = data.whitelist.find c.id

    if loc == -1:
      await astrea.api.sendInteractionMessage(i, "Can't remove something that was never in the whitelist!")
      return

    data.whitelist.delete(loc)
    await astrea.api.sendInteractionMessage(i, "Channel removed from the whitelist!")
    await data.save()

cmd.addSlash("dm blacklist remove") do (channel: Option[GuildChannel]):
  ## Unblacklists a channel for pinging
  if canUseCommand(i, channel).await:
    let
      c = channel.get (await astrea.api.getChannel(i.channel_id.get()))[0].get()
      loc = data.blacklist.find c.id

    if loc == -1:
      await astrea.api.sendInteractionMessage(i, "Can't remove something that was never in the blacklist!")
      return

    data.blacklist.delete(loc)
    await astrea.api.sendInteractionMessage(i, "Channel removed from the blacklist!")
    await data.save()

cmd.addSlash("dm timeout") do(channel: Option[GuildChannel], hours, minutes, seconds: Option[int]):
  ## Change a timeout for a channel! Default is 5 mins
  if canUseCommand(i, channel).await:
    let
      c = channel.get (await astrea.api.getChannel(i.channel_id.get()))[0].get()
      hrs = hours.get(0)
      mins = minutes.get(
        if (seconds.isSome) or (hours.isSome):
          0
        else:
          5
      )
      secs = seconds.get(0)

    if c.isWhitelisted().await:
      if (hrs == 0) and (mins == 5) and (secs == 0):
        data.customCooldowns.del(c.id)
      else:
        data.customCooldowns[c.id] = initDuration(hours=hrs, minutes=mins, seconds=secs)
      await astrea.api.sendInteractionMessage(i, "Changed the channel's timeout!")
      await data.save()

    else:
      await astrea.api.sendInteractionMessage(i, "This channel isn't whitelisted, so it can't have a custom timeout applied!")
