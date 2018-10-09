###*
 * Set of wrappers to builder
###
Object.defineProperties GridFW.prototype,
	### add middleware ###
	use: value: (route, middleware)->
		[route, middleware] = ['/*', route] if arguments.length is 1
		# add middleware
		@all route, m: middleware
	###*
	* add param
	* @example
	* app.param('paramName', /^\d+$/)
	* app.param('paramName', (data, ctx)=> data)
	* app.param('paramName', /^\d+$/, (data, ctx)=> data)
	* app.param('/path', 'paramName', /^\d+$/, (data, ctx)=> data)
	###
	param: value: (route, paramName, regex, resolver)->
		switch arguments.length
			# app.param(paramName, regex)
			# app.param(paramName, resolverFx)
			when 2
				if typeof paramName is 'function'
					resolver = paramName
				else if paramName instanceof RegExp
					regex = paramName
				else
					throw new Error 'Illegal arguments'
				paramName = route
				route = '/*'
			# app.param(paramName, regex, resolver)
			# app.param(route, paramName, regex)
			# app.param(route, paramName, resolver)
			when 3
				# app.param(route, paramName, regex)
				# app.param(route, paramName, resolver)
				if typeof paramName is 'string'
					if typeof regex is 'function'
						[regex, resolver] = [null, regex]
					else unless regex instanceof RegExp
						throw new Error 'Illegal arguments'
				# app.param(paramName, regex, resolver)
				else if paramName instanceof RegExp
					[route, paramName, regex, resolver] = ['/*', route, paramName, regex]
				else
					throw new Error 'Illegal arguments'
			# app.param(route, paramName, regex, resolver)
			when 4
			else
				throw new Error 'Illegal arguments'
		throw new Error 'Param name expected string' unless typeof paramName is 'string'
		@all route, $: [paramName]: [regex, resolver]
	###*
	 * Add filter
	 * @example
	 * app.filter('/route', filterFx(ctx){})
	###
	filter: value: (route, handler)->
		[route, middleware] = ['/*', route] if arguments.length is 1
		@all route, f: handler
	###*
	 * Post process
	###
	finally: value: (route, handler)->
		[route, middleware] = ['/*', route] if arguments.length is 1
		@all route, p: handler
	###*
	 * Error handler
	 * @example
	 * app.catch('/path', handler)
	###
	catch: value: (route, handler)->
		[route, middleware] = ['/*', route] if arguments.length is 1
		@all route, e: handler

###*
 * Route wrappers
###
HTTP_SUPPORTED_METHODS.forEach (method)->
	Object.defineProperty GridFW.prototype, method,
		value: (route, handler)->
			switch arguments.length
				when 2
					@on method, route, handler
				when 1
					@on method, route
				else
					throw new Error 'Illegal arguments'