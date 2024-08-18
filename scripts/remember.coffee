# Description
#   Remembers a key and value
#
# Commands:
#   hubot rem|remember|what is <key> - Returns a string.
#   hubot rem|remember <key> is <value> - Returns nothing. Remembers the text for next time!
#   hubot replace <key> with <value> - Returns nothing. Replaces an existing memory with new text.
#   hubot forget <key> - Removes key from hubots brain.
#   hubot what are your favorite memories? - Returns a list of the most remembered memories.
#   hubot me|random memory - Returns a random memory.
#   hubot me|random memory <prefix> - Returns a random memory whose key matches the prefix.
#
# Dependencies:
#   "underscore": "*"

_ = require('underscore')

module.exports = (robot) ->
  memoriesByRecollection = () -> robot.brain.data.memoriesByRecollection ?= {}
  memories = () -> robot.brain.data.remember ?= {}

  findSimilarMemories = (key) ->
    searchRegex = new RegExp(key, 'i')
    Object.keys(memories()).filter (key) -> searchRegex.test(key)

  robot.respond /(?:what is|rem(?:ember)?)\s+(.*)/i, (msg) ->
    msg.finish()
    words = msg.match[1].trim()

    # First check for a search expression.
    if match = words.match /\|\s*(grep\s+)?(.*)$/i
      searchPattern = match[2]
      matchingKeys = findSimilarMemories(searchPattern)
      if matchingKeys.length > 0
        msg.send "I remember:\n#{matchingKeys.join(', ')}"
      else
        msg.send "I don't remember anything matching `#{searchPattern}`"
      return

    # Next, attempt to interpret `words` as an existing key.
    if match = words.match /([^?]+)\??/i
      key = match[1].toLowerCase()
      value = memories()[key]

      if value
        memoriesByRecollection()[key] ?= 0
        memoriesByRecollection()[key]++
        msg.send value
        return

    # Next, attempt to interpret `words` as a "foo is bar" expression in order
    # to store a memory.
    if match = words.match /^(.*)is(.*)$/i
      key = match[1].trim().toLowerCase()
      value = match[2].trim()
      if key and value
        currently = memories()[key]
        if currently
          msg.send "But #{key} is already #{currently}.  Forget #{key} first."
        else
          memories()[key] = value
          msg.send "OK, I'll remember #{key}."
        return

    # If none of the previous actions succeeded, search existing memories for
    # similar keys.
    matchingKeys = findSimilarMemories(words)
    if matchingKeys.length > 0
      keys = matchingKeys.join(', ')
      msg.send "I don't remember `#{words}`. Did you mean:\n#{keys}"
    else
      msg.send "I don't remember anything matching `#{words}`"

  robot.respond /replace\s+(.*)/i, (msg) ->
    words = msg.match[1].trim()
    if match = words.match /(.*?)(\s+with\s+([\s\S]*))$/i
      msg.finish()
      key = match[1].toLowerCase()
      value = match[3]
      currently = memories()[key]
      memories()[key] = value
      if currently
        msg.send "OK, #{key} has been updated."
      else
        msg.send "I don't remember #{key}, but I'll remember it now!"

  robot.respond /forget\s+(.*)/i, (msg) ->
    key = msg.match[1].toLowerCase()
    value = memories()[key]
    if value
      delete memories()[key]
      delete memoriesByRecollection()[key]
      msg.send "I've forgotten #{key} is #{value}."
    else
      msg.send "I don't remember anything matching `#{key}`... so we're probably all good?"

  robot.respond /what are your favorite memories/i, (msg) ->
    msg.finish()
    sortedMemories = _.sortBy Object.keys(memoriesByRecollection()), (key) ->
      memoriesByRecollection()[key]
    sortedMemories.reverse()

    msg.send "My favorite memories are:\n#{sortedMemories[0..20].join(', ')}"

  robot.respond /(me|random memory)(\s+.+)?$/i, (msg) ->
    msg.finish()

    randomKey = if msg.match[2]
      msg.random(findSimilarMemories(msg.match[2].trim()))
    else
      msg.random(Object.keys(memories()))

    msg.send randomKey
    msg.send memories()[randomKey]

  robot.respond /mem(ory)? bomb x?(\d+)/i, (msg) ->
    keys = []
    keys.push value for key,value of memories()
    unless msg.match[2]
      count = 10
    else
      count = parseInt(msg.match[2])

    msg.send(msg.random(keys)) for [1..count]
