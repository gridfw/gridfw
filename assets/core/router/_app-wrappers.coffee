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