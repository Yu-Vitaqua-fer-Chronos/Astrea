import std/[
  asyncdispatch,
  strutils,
  options
]

import dimscord
#import dimscmd

proc sendInteractionMessage*(api: RestApi, i: Interaction,
  content = "", tts = false,
  allowedMentions = none AllowedMentions, embeds = newSeq[Embed](),
  components = newSeq[MessageComponent](),
  flags: set[MessageFlags]={}) {.async.} =

  var am: AllowedMentions

  if allowedMentions.isSome:
    am = allowedMentions.get()

  await interactionResponseMessage(api, i.id, i.token,
    irtChannelMessageWithSource,
    InteractionApplicationCommandCallbackData(
      tts: tts.some, embeds: embeds, content: content, flags: flags,
      components: components, allowedMentions: am
    )
  )

proc hasPerms*(po: PermObj, perms: varargs[PermissionFlags]): bool =
  result = true
  for perm in perms:
    if perm notin po.allowed:
      return false
