###*
 * Extends app methods and attributes
 * @example
 * app.addProperties
 * 		Context: 
 * 			// context properties
 * 		Request:
 * 			// request properties
 * 		// other app properties
###
GridFW::addProperties = (pluginName, properties)->
	if arguments.length is 1
		@warn 'AddProperties', 'Expected plugin name for debug purpose'
		[pluginName, properties]= ['', pluginName]
	else unless arguments.length is 2
		throw new Error 'Expected two arguments'

	throw new Error 'Expected object' unless (typeof properties is 'object') and properties
	# add properties
	for p in ['App', 'Context', 'Request']
		if p of properties
			src = properties[p]
			target= if p is 'App' then this else @[p].prototype
			throw new Error "#{p} expected object" unless (typeof src is 'object') and src
			# add properties
			descrptr= Object.getOwnPropertyDescriptors src
			for k,v of descrptr
				v.enumerable = off
				v.configurable= on
				v.writable = off if v.hasOwnProperty 'writable'
				# if override
				descriptor2 = Object.getOwnPropertyDescriptor target, k
				if descriptor2
					# continue if the same
					if 'value' of descriptor2
						continue if descriptor2.value is v.value
					else
						continue if (descriptor2.get is v.get) and (descriptor2.set is v.set)
					# add property
					if descriptor2.configurable
						@warn 'CORE', "Override property of #{p}: #{pluginName}::#{k}"
					else
						@error 'CORE', "Could not override property of #{p}: #{pluginName}::#{k}"
						continue
				else
					@debug 'CORE', "Add property to #{p}: #{pluginName}::#{k}"	
				# Add property
				_defineProperty target, k, v
	return
###*
 * remove app methods and attributes
 * @example
 * app.removeProperties
 * 		Context: 
 * 			// context properties
 * 		Request:
 * 			// request properties
 * 		// other app properties
###
GridFW::removeProperties = (pluginName, properties)->
	if arguments.length is 1
		@warn 'AddProperties', 'Expected plugin name for debug purpose'
		[pluginName, properties]= ['', pluginName]
	else unless arguments.length is 2
		throw new Error 'Expected two arguments'

	throw new Error 'Expected object' unless (typeof properties is 'object') and properties
	# add properties
	for p in ['App', 'Context', 'Request']
		if p of properties
			src = properties[p]
			target = if p is 'App' then this else @[p].prototype
			throw new Error "#{p} expected object" unless (typeof src is 'object') and src
			# delete properties
			for k,v of src
				if v is target[k]
					delete target[k]
					@debug 'CORE', "Remove property from #{p}: #{pluginName}::#{k}"
	return

