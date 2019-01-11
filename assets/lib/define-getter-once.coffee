'use strict'
###
this function will add a getter with a called once function
the result value will be cached in the object
###
#=include ../commons/_index.coffee
module.exports =
	# define one getter one
	getterOnce: (proto, name, genFx)->
		_defineProperty proto, name,
			get: ->
				value = genFx.call this
				_defineProperty this, name, value: value
				value

	# define multiple getters
	gettersOnce: (proto, descriptor)->
		# init descriptor
		for k,v of descriptor
			throw new Error "Illegal getter of #{k}" unless typeof v is 'function'
			descriptor[k] = _getterProxy k, v
		# define
		_defineProperties proto, descriptor


_getterProxy = (k, v)->
	get: ->
		value = v.call this
		_defineProperty this, k, value: value
		value