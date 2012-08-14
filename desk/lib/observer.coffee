Util = require 'lib/util'

module.exports = class Observer
  listeners: {}
  ## Model Event stuff ##
  bind: (el, key, fn) ->
    if Util.isString el
      [key, fn] = [el, key]
      (@listeners[key] ?= []).push fn
    else if el.bind?
      el.bind key, fn
    else
      el.addEventListener key, fn, no
  trigger: (key, args...) ->
    if Util.isString key
      listener args... for listener in @listeners[key] if @listeners?[key]?
    else if el.trigger?
      el.trigger key, args...
    else
      key.dispatchEvent args[0]
  unbind: (el, key, fn) ->
    if Util.isString el
      [key, fn] = [el, key]
      if @listeners[key]?.length > 0
        for callback, index in @listeners[key]
          if callback == fn
            @listeners[key].splice index, 1
            return yes
      no
    else if el.unbind?
      el.unbind key, fn
    else
      el.removeEventListener key, fn, no
  ## End Model Event stuff ##