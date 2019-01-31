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
GridFW::addProperties = (properties)->
	throw new Error 'Expected one argument' unless arguments.length is 1
	throw new Error 'Expected object' unless (typeof properties is 'object') and properties
	# add properties
	for p in ['App', 'Context', 'Request']
		if p of properties
			src = properties[p]
			target= if p is 'App' then this else @[p]
			throw new Error "#{p} expected object" unless (typeof src is 'object') and src
			_extendsAddProperties this, src, (), k
			# add properties
			for k,v of src
				# descriptor
				descrptr = Object.getOwnPropertyDescriptor src, k
				descrptr.writable = descrptr.enumerable = off
				# if override
				if k of target
					descriptor2 = Object.getOwnPropertyDescriptor target, k
					# continue if the same
					if 'value' of descriptor2
						continue if descriptor2.value is descrptr.value
					else
						continue if (descriptor2.get is descrptr.get) and (descriptor2.set is descrptr.set)
					# add property
					if descriptor2.configurable
						app.warn 'ADD-PROPERTY', "Override property #{p}.#{k}"
					else
						app.error 'ADD-PROPERTY', "Could not override property #{p}.#{k}"
						continue
				else
					app.error 'ADD-PROPERTY', "Add property #{p}.#{k}"	
				# Add property
				_defineProperty target, k, descriptor
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
GridFW::removeProperties = (properties)->
	throw new Error 'Expected one argument' unless arguments.length is 1
	throw new Error 'Expected object' unless (typeof properties is 'object') and properties
	# add properties
	for p in ['App', 'Context', 'Request']
		if p of properties
			src = properties[p]
			target = if p is 'App' then this else @[p]
			throw new Error "#{p} expected object" unless (typeof src is 'object') and src
			# delete properties
			for k,v of src
				if v is target[k]
					delete target[k]
					app.debug 'ADD-PROPERTY', "Remove property #{p}.#{k}"
	return

