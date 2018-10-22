
Object.defineProperties GridFW.prototype,
	###*
	* add param
	* @example
	* app.param('paramName', /^\d+$/)
	* app.param('paramName', (data, ctx)=> data)
	* app.param('paramName', /^\d+$/, (data, ctx)=> data)
	###
	param: value: (paramName, regex, resolver)->
		# fix args
		switch arguments.length
			when 3
				throw new Error 'param name expected string' unless typeof paramName is 'string'
				throw new Error "Param name [#{paramName}] already set" if @$[paramName]
				throw new Error 'regex expected RegExp' if regex and not (regex instanceof RegExp)
				throw new Error 'resolver expect function' unless typeof resolver is 'function'
				@.debug 'CORE', "Define param #{paramName}: #{regex}"
				@$[paramName] = [regex || EMPTY_REGEX, resolver]
			when 2
				if typeof regex is 'function'
					@param paramName, null, regex
				else
					@param paramName, regex, EMPTY_PARAM_RESOLVER
			else
				throw new Error 'Illegal arguments'
		# chain
		this