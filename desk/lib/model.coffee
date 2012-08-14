Collection = require 'lib/collection'
Util = require 'lib/util'
Observer = require 'lib/observer'

valueOrDefault = (value, def) ->
  return value if value or not def?
  if Util.isFunction def then def() else def

class Model
  @field: (name, options = {}) ->
    @fields ?= {}
    @fields[name] = options
  @has_many: (klass, options = {}) ->
    options.klass = klass
    options.as ?= "#{klass.name.toLowerCase()}s"
    @collections ?= {}
    @collections[options.as] = options
  @has_one: (klass, options = {}) ->
    options.klass = klass
    options.as ?= "#{klass.name.toLowerCase()}s"
    @relations ?= {}
    @relations[options.as] = options
  
  constructor: (attributes) ->
    @attributes = {}
    @validators = {}
    @types = {}
    # use attributes or defaults
    for name, options of @constructor.fields
      @types[name] = options.type or String
      value = valueOrDefault attributes?[name], options.default
      if attributes?[name] is null
        @attributes[name] = null
      else if typeof attributes?[name] is 'undefined'
        @attributes[name] = undefined
      else if value?.prototype?
        @attributes[name] = value if value instanceof @types[name]
      else
        @attributes[name] = @types[name] value
    for name, options of @constructor.collections
      @[name] = new Collection @, options
      @[name].create attrs for attrs in attributes[name] if attributes?[name]?
    for name, options of @constructor.relations
      @[name] = new options.klass attributes[name]
    @listeners = {}
  
  has: (attr) ->
    @constructor.fields[attr]?
  
  ## Getter and Setter ##
  get: (attr) ->
    return @attributes[attr] if @has attr
    throw new TypeError "Attribute with the name '#{attr}' not found."
  
  set: (attr, value) ->
    throw new TypeError "Attribute with the name '#{attr}' not found." unless @has attr
    throw new TypeError "Attribute doesn't allow '#{typeof value}'." if value.prototype? and not value instanceof @types[attr]
    oldValue = @get attr
    
    # ignore the same value
    return unless value and value isnt oldValue
    
    @trigger 'beforechange', attr, value, oldValue
    @trigger "beforechange:#{attr}", value, oldValue
    if value.prototype?
      @attributes[attr] = value
    else
      @attributes[attr] = @types[attr](value)
    @trigger 'change', attr, value, oldValue
    @trigger "change:#{attr}", value, oldValue
    @
  
  getAttributes: ->
    @attributes
  
  setAttributes: (attrs) ->
    @trigger 'beforechange', attrs
    for attr, value of attrs
      throw new TypeError "Attribute with the name '#{attr}' not found." unless @has attr
      throw new TypeError "Attribute doesn't allow '#{typeof value}'." if value.prototype? and not value instanceof @types[attr]
      oldValue = @get attr
      
      # ignore the same value
      continue unless value and value isnt oldValue
      
      @trigger "beforechange:#{attr}", value, oldValue
      if value.prototype?
        @attributes[attr] = value
      else
        @attributes[attr] = @types[attr] value
      @trigger "change:#{attr}", value, oldValue
    
    @trigger 'change', attrs
    @
  ## End Getter and Setter ##

## Model Event stuff ##
Util.extend Model.prototype, Observer.prototype

module.exports = Model