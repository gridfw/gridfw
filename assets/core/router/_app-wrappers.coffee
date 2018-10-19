###*
 * @deprecated 
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
