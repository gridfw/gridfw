# Object
_create = Object.create
_defineProperty = Object.defineProperty
_defineProperties = Object.defineProperties
_assign= Object.assign
_keys= Object.keys

# Reflect
_has= Reflect.has

# Array
_isArray= Array.isArray
_arrRemove= (arr, element)->
	len= arr.length
	i=0
	while i<len
		if arr[i] is element
			arr.splice(i,1)
		else
			++i
	return

# Getters once
_getterProxy = (k, v)->
	get: ->
		value = v.call this
		_defineProperty this, k,
			configurable: true
			enumerable: true
			value: value
			writable: true
		return value
_defineGettersOnce= (prototype, descrp)->
	for k,v of descrp
		descrp[k]= _getterProxy k,v
	_defineProperties prototype, descrp
	return


# LOG IGNORE
LOG_IGNORE= ->