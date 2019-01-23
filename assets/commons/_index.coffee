###
Common utilites
###

###*
 * Create new object
###
_create = Object.create
_defineProperty = Object.defineProperty
_defineProperties = Object.defineProperties

_defineReconfigurableProperties = (obj, properties)->
	properties = Object.getOwnPropertyDescriptors properties
	for k,v of properties
		v.configurable = on
		v.enumerable= off
		v.writable= off
	_defineProperties obj, properties



#=include _check-options.coffee