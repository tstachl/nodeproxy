module.exports = class Util
  @throttle = (fn, delay) ->
    timer = null
    (args...) ->
      clearTimeout timer
      timer = setTimeout =>
        fn.apply(@, args)
      , delay
  
  # test if object is a function
  @isFunction: (obj) ->
    Object.prototype.toString.call(obj) is '[object Function]'
  
  @isArray: (obj) ->
    Object.prototype.toString.call(obj) is '[object Array]'
  
  @isObject: (obj) ->
    obj is Object obj
  
  @isString: (obj) ->
    typeof obj is 'string' and isNaN obj
  
  # create a (shallow-cloned) duplicate of an object
  @clone: (obj) ->
    return obj unless Util.isObject(obj)
    if Util.isArray obj then obj.slice() else Util.extend obj
  
  @extend: (obj, args...) ->
    for arg in args
      for prop of arg
        obj[prop] = arg[prop]
    obj
      
    
    
