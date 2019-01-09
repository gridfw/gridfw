# check route wrapper
# _fixRouteWrapper = (route)->
# 	assetRoute route
# 	# reject wildcard params
# 	throw new Error 'Wildcard params are not allowed: ' + route if /\/?\*\w+$/.test route
# 	# route mast starts width "/"
# 	route = '/' + route unless route.startsWith '/'
# 	# remove wildcard
# 	route = route.slice(0, -2) || '/' if route.endsWith '/*'
# 	# return
# 	route

### flatten routes ###
# _flattenWrapper = (fx)->
# 	value: (route, handler)->
# 		# check arguments
# 		# switch arguments.length
# 		# 	when 2
# 		# 	when 1
# 		# 		[route, handler] = ['/', route]
# 		# 	else
# 		# 		throw new Error 'Illegal arguments'
# 		throw new Error "handler expected function" unless typeof handler is 'function'
# 		fx.call this, route, handler
# 		return this

### add methods ###
_defineProperties GridFW.prototype,
	###*
	* add param
	* @see doc::param
	###
	param: value: (options)->
		throw new Error 'Illegal arguments' unless arguments.length is 1 and typeof options is 'object' and options
		paramName = options.name
		throw new Error 'Param name is required and expected string' unless typeof paramName is 'string'
		# prepare options
		if options.resolver or options.matches
			# matches
			matches = options.matches
			if matches
				if typeof matches is 'function'
					matches = _create null, test: value: matches
				else unless matches instanceof RegExp
					throw new Error '"matches" expected RegExp or function'
			else
				matches = EMPTY_REGEX
			# resolver
			resolver = options.resolver
			if resolver
				throw new Error "Resolver expected function" unless typeof resolver is 'function'
			else
				resolver = EMPTY_PARAM_RESOLVER
			paramV = [matches, resolver]
		else
			paramV = EMPTY_PARAM
		# save
		if @$[paramName] and @$[paramName] isnt EMPTY_PARAM
			@warn 'CORE', "Overriding Param [#{paramName}]"
		else
			@debug 'CORE', "Define param [#{paramName}]"
		@$[paramName] = paramV
		# chain
		this

	###*
	 * Add an express middleware for a route and its subroutes
	 * @deprecated express middlewares are executed for each request. use Gridfw plugins for more performance or app.wrap instead
	###
	# use: (route, middleware)->
	# 	# check arguments
	# 	if arguments.length is 1
	# 		return @use '/', middleware
	# 	else unless arguments.length is 2
	# 		throw new Error 'Illegal arguments'
	# 	@warn 'core', 'use of expressjs middleware'
	# 	# select subroutes
	# 	if route.endsWith '/'
	# 		route += '*'
	# 	else unless route.endsWith '/*'
	# 		route += '/*'
	# 	# wrap
	# 	switch middleware.length
	# 		when 3 # expressjs middleware
	# 			@wrap route, (controller)->
	# 				(ctx)->
	# 					new Promise (resolve, reject)=>
	# 						middleware ctx.req, ctx, =>
	# 							resolve controller.call this, ctx
	# 			app.all(route).wrap (ctx, controller)->
	# 				new Promise (resolve, reject)=>
	# 					middleware ctx.req, ctx, =>
	# 						resolve controller.call this, ctx
	# 						return
	# 					return
	# 			.build()
	# 		when 4 # error handler
	# 			app.all(route).catch (ctx)->
	# 				new Promise (resolve, reject)->
	# 					middleware ctx.error, ctx.req, ctx, resolve
	# 					return
	# 			.build()
	# 	# chain
	# 	this
	###*
	 * Error handling
	###
	catch: (route, handler)->
		# flatten routes
		if Array.isArray route
			for v in route
				@catch v, handler
			return
		# check arguments
		switch arguments.length
			when 2
				break
			when 1
				[route, handler] = ['/', route]
			else
				throw new Error 'Illegal arguments'
		throw new Error 'Handler expected function' unless typeof handler is 'function'
		# adjust route (remove /*)
		if route is '/*'
			route = '/'
		else if route.endsWith '/*'
			route = route.slice 0, -2
		# add error handler
		mapper = _createRouteTree this, route
		(mapper.E ?= []).push handler
		(mapper.e ?= []).push handler
		# propagate middleware to subroutes
		_AjustRouteHandlers mapper
		# chain
		this
	###*
	 * wrap request
	 * #TODO
	###
	wrap: (route, handler)->
		switch arguments.length
			# route wrapping
			when 2
				# check handler
				throw new Error 'Wrapper expected function' unless typeof handler is 'function'
				throw new Error "Wrapper[@{route}] format expected: function wrapper(controller){return function(ctx){}}" unless handler.length is 1
				mapper = _createRouteTree this, route
				(mapper.W ?= []).push handler
				(mapper.w ?= []).push handler
				_AjustRouteHandlers mapper
				# clear route cache
				do @_clearRCache
			# request handling wrapping
			when 1
				handler = route
				throw new Error 'Wrapper expected function' unless typeof handler is 'function'
				@_handleWrappers.push handler
				# create new handler
				_rebuildRequestHandler this
			# error
			else
				throw new Error 'Illegal arguments'
		# chain
		this
	unwrap: (route, handler)->
		switch arguments.length
			# remove wrapper from route
			when 2
				mapper = _createRouteTree this, route, no
				if mapper
					_arrayRemove mapper.W, handler if mapper.W
					_arrayRemove mapper.w, handler if mapper.w
					_AjustRouteHandlers mapper
					# clear route cache
					do @_clearRCache
			# remove wrapper from request handler
			when 1
				_arrayRemove @_handleWrappers, handler
				_rebuildRequestHandler this
			else
				throw new Error 'Illegal arguments'
		# chain
		this
	### clear route cache ###
	_clearRCache: value: ->
		@[CACHED_ROUTES] = _create null if @[IS_LOADED]

### rebuild request handler ###
_rebuildRequestHandler = (app)->
	#TODO