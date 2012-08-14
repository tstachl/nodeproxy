Util = require 'lib/util'

module.exports = class Collection
  # Using CoffeeScript destructuring bind to extract the bits we need from options
  constructor: (@parent, {as: @field_name, klass: @klass}) ->
    @members = []
  
  create: (attributes) =>
    @add new @klass(attributes)
  
  add: (thing) =>
    @members.push thing
    @parent.trigger 'add', thing
    @parent.trigger "add:#{@field_name}", thing
    thing
  
  remove: (thing) =>
    for _thing, i in @members when _thing is thing
      delete @members[i]
      @parent.trigger 'remove', thing
      @parent.trigger "remove:#{@field_name}", thing
      break
  
  all: =>
    Util.clone @members
  
  length: =>
    @members.length
  
  at: (index) =>
    @members[index]
  
  first: ->
    return @members[0] if @length() > 0
    null
  
  last: ->
    return @members[@length() - 1] if @length() > 0
    null
  
  find_by: (key, value) ->
    for _thing, i in @members when _thing.attributes[key] is value
      return _thing
    null
  
  next: (thing) ->
    for _thing, i in @members when _thing is thing
      if _thing is @last()
        return @first()
      else
        return @at(i+1)
  
  prev: (thing) ->
    for _thing, i in @members when _thing is thing
      if _thing is @first()
        return @last()
      else
        return @at(i-1)