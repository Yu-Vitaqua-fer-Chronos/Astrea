import dimscord # For `ActivityStatus`

type
  Config* = object
    token*: string
    randomPrompts*: bool = true

  Data* = object
    prompts*: seq[string] = newSeq[string](0)
    whitelist*: seq[string] = newSeq[string](0)
    blacklist*: seq[string] = newSeq[string](0)
    activities*: seq[ActivityStatus] = newSeq[ActivityStatus](0)
