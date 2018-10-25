# check route wrapper
_fixRouteWrapper = (route)->
	assetRoute route
	# reject wildcard params
	throw new Error 'Wildcard params are not allowed: ' + route if /\/?\*\w+$/.test route
	# route mast starts width "/"
	route = '/' + route unless route.startsWith '/'
	# remove wildcard
	route = route.slice(0, -2) || '/' if route.endsWith '/*'
	# return
	route

### flatten routes ###
_flattenRouteWrapper = (fx)->
	value: (route, handler)->
		switch arguments.length
			when 2
				if Array.isArray route
					for r in route
						fx.call this, _fixRouteWrapper(r), middleware
					return this
				else
					fx.call this, _fixRouteWrapper(route), handler
			when 1
				fx.call this, '/', route
			else
				throw new Error 'Illegal arguments'
		return this

### add methods ###
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
				throw new Error 'regex expected RegExp' if regex and not (regex instanceof RegExp)
				throw new Error 'resolver expect function' unless typeof resolver is 'function'
				throw new Error "Param name [#{paramName}] already set" if @$[paramName] and @$[paramName] isnt EMPTY_PARAM
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

	###*
	 * Add middleware for a route and its subroutes
	 * middlewares do not allow wildcards
	 * @example
	 * @use middleware
	 * @use '/path', middleware
	###
	use: _flattenRouteWrapper (route, middleware)->
		# check middleware
		throw new Error 'Middleware expected function' unless typeof middleware is 'function'
		# convert middleware express like to gridwf
		if middleware.length is 3
			orMiddleware = middleware
			@warn 'RTER', 'Use of ExpressJS like middleware'
			middleware = (ctx)->
				new Promise (resolve, reject)->
					orMiddleware ctx.req, ctx, (err)->
						if err
							reject err
						else
							do resolve
		# convert express error handler 
		else if middleware.length is 4
			return @catch route, middleware
		else unless middleware.length is 1
			throw new Error 'Middleware expects one argument. When express middleware, 3 or 4 arguments are expected.'
		# map
		mapper = _createRouteTree this, route
		(mapper.M ?= []).push middleware
		(mapper.m ?= []).push middleware
		# propagate middleware to subroutes
		_AjustRouteHandlers mapper
		# chain
		this
	###*
	 * Error handling
	###
	catch: _flattenRouteWrapper (route, handler)->
		# check handler
		throw new Error 'Error handler expected function' unless typeof handler is 'function'
		# convert middleware express like to gridwf
		if handler.length is 4
			orHandler = handler
			@warn 'RTER', 'Use of ExpressJS like Error handler'
			handler = (ctx)->
				new Promise (resolve, reject)->
					orHandler ctx.error, ctx.req, ctx, (err)->
						if err
							reject err
						else
							do resolve
		# convert express error handler 
		else unless handler.length in [1, 2]
			throw new Error 'Error handler expect function(err, ctx){}. (or ExpressJS error handler)'
		# 
		mapper = _createRouteTree this, route
		(mapper.E ?= []).push handler
		(mapper.e ?= []).push handler
		# propagate middleware to subroutes
		_AjustRouteHandlers mapper
		# chain
		this
	###*
	 * Add controller wrapper
	###
	wrap: _flattenRouteWrapper (route, handler)->
		# check handler
		throw new Error 'Wrapper expected function' unless typeof handler is 'function'
		throw new Error "Wrapper[@{route}] format expected: function wrapper(controller){return function(ctx){}}" unless handler.length is 1
		mapper = _createRouteTree this, route
		(mapper.W ?= []).push handler
		(mapper.w ?= []).push handler
		_AjustRouteHandlers mapper
		# clear route cache
		do @_clearRCache
		# chain
		this

	### clear route cache ###
	_clearRCache: value: ->
		@[CACHED_ROUTES] = Object.create null if @[IS_LOADED]