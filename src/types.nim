import std/[
  tables,
  times
]

import dimscord # For `ActivityStatus`

type
  Config* = object
    token*: string
    randomPrompts*: bool = true

  Data* = object
    prompts*: seq[string] = newSeq[string](0)
    whitelist*: seq[string] = newSeq[string](0)
    blacklist*: seq[string] = newSeq[string](0)
    cannotSend*: Table[string, seq[string]] = initTable[string, seq[string]]()
    customCooldowns*: Table[string, Duration] = initTable[string, Duration]()
    activities*: seq[ActivityStatus] = newSeq[ActivityStatus](0)
    linkedChannels*: Table[string, seq[string]] = initTable[string, seq[string]]()