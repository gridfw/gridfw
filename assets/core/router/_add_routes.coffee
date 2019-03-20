###*
 * Add routes
 * Supported routes
 **** static routes
 * /path/to/static/route
 * /path/containing/*stars/is-supported
 **** to escape "*" and ":" use "?*" and "?:"
 * /wildcard/in/the/last/mast/be/escaped/?*
 * /semi/?:colone/mast/be/escaped:if:after:slash:only
 **** dynamic path
 * /dynamic/:param1/path/:param2
 * /dynamic/:param/* # the rest of path will be stored inside param called "*"
 * /dynamic/:param/*rest # the rest of path will be stored in the param "rest"
###
_defineProperties GridFW.prototype,
	###*
	 * Add a route
	 * @example
	 * Route.on('GET', '/path/to/resource', handler)
	 * .on(['GET', 'HEAD'], ['/path/to/resource', '/path2/to/src'], handler)
	 * .on(['GET', 'HEAD'], ['/path/to/resource', '/path2/to/src'], {m:middleware, p:postProcess, ...})
	 * .on('GET', '/path/to/resource')
	 * 		.then(handler)
	 * 		.end # go back to route
	 * .on('GET', '/path/to/resource')
	 * 		# user promise like processing
	 * 		.then(handler)
	 * 		.then(handler2)
	 * 		.catch(err => {})
	 * 		.then(handler3)
	 * 		.finally(handler)
	 * 		.then(handler)
	 * 		
	###
	on: value: (method, route, handler)->
		try
			# clear route cache
			do @_clearRCache
			# Add handlers
			switch arguments.length
				# .on 'GET', '/route', handler
				when 3
					if (typeof handler is 'function') or (handler instanceof GridFW)
						# throw new Error 'handler could take only one argument' if handler.length > 1
						_createRouteNode this, method, route, handler
					else
						throw new Error 'Illegal handler'
					# chain
					return this
				# .on 'GET', '/route'
				# create new node only if controller is specified, add handler to other routes otherwise
				when 2
					# do builder
					return new _RouteBuiler this, (handler)=> _createRouteNode this, method, route, handler
				else
					throw new Error '[app.on] Illegal arguments ' + JSON.stringify arguments
		catch err
			throw new GError 500, "Route creation fails: #{method} #{route}", err
		
	###*
	 * Remove route
	 * @example
	 * .off('alll', '/route', handler) # remove this handler (as controller, preprocess, postprocess, errorHandler, ...)
	 * 									from this route for all http methods
	 * .off('GET', '/route') # remove this route
	###
	#TODO remove route, post process or any handler
	off: value: (method, route, handler)->
		# check method
		throw new Error 'method expected string' unless typeof method is 'string'
		method = method.toUpperCase()
		throw new Error "Unknown http method [#{method}]" unless method in HTTP_METHODS

		throw new Error 'Unimplemented'
		# exec
		# switch arguments.length
		# 	# off(method, route)
		# 	when 2:
		# 		if method
		#TODO

	# when called before plugin render added, wait for app to load
	loadStaticViews: value: (route, path)->
		throw new Error 'Render lib missing' if @[IS_LOADED]
		@[APP_STARTING_PROMISE].then => @loadStaticViews route, path

	# re-adjust all routes
	_rebuildRoutes: value: ->
		_AdjustRouteMappers @['/']
		return


###*
 * Create route node or add handlers to other routes
 * @optional @param {object} descrp - other optional params
###
_createRouteNode = (app, method, route, handler)->
	# flatten method
	if Array.isArray method
		for v in method
			_createRouteNode app, v, route, handler
		return
	# check method
	throw new Error 'method expected string' unless typeof method is 'string'
	method = method.toUpperCase()
	throw new Error "Unknown http method [#{method}]" unless method is 'ALL' || method in HTTP_METHODS
	# flatten route
	if Array.isArray route
		for v in route
			_createRouteNode app, method, v, handler
		return
	# check route
	assertRoute route
	
	# settings
	settings = app.s
	ignoreCase = settings[<%= settings.routeIgnoreCase %>]
	# remove trailingSlash from route
	unless settings[<%= settings.trailingSlash %>]
		route = route.slice 0, -1 if route.endsWith '/'
	# route mast starts width "/"
	route = '/' + route unless route.startsWith '/'
	# fix route
	# replace '/:' and '/*' with '/?:' and '/?*'
	# replace '/?:' and '/?*' with '/:' and '/*'
	originalRoute = route # for debuging
	route = route.replace /\/([:*?])/g, (_, k)->
		if k is '?' then '/' else '/?' + k
	# check if it is a static or dynamic route
	isDynamic = /\/\?/.test route
	# lowercase and encode static parts
	if isDynamic
		app.debug 'RTER', "Map dynamic\t: #{method} #{originalRoute}"
		route = route.replace /\/([^?][^\/]*)/g, (v)->
			v = v.toLowerCase() if ignoreCase
			Encodeurl v
	else
		app.debug 'RTER', "Map static\t: #{method} #{originalRoute}"
		route = route.toLowerCase() if ignoreCase
		route = Encodeurl route
	# get or create route tree
	mapper = _createRouteTree app, route
	# add controller
	if handler
		# simple handler
		# mounted app
		unless typeof handler is 'function'
			throw new Error 'Controller mast be function or Gridfw app' unless handler instanceof GridFW
			handler = _mount app, handler, method, originalRoute
		# map
		app.warn 'RTER', "Route controller overrided: #{method} #{originalRoute}" if mapper[method]
		mapper[method] = handler
		# mapper['_' + method] = handler

	# optional operations
	# if descrp
	# 	# wrappers
	# 	if descrp.wrappers.length
	# 		app.info 'RTER', "Wrap controller at: #{method} #{originalRoute}"
	# 		handler = mapper[method]
	# 		throw new Error 'No controller to wrap at: #{method} #{originalRoute}' unless handler
	# 		for wrap in descrp.wrappers
	# 			handler = wrap handler
	# 			throw new Error "Illegal wrapper response! wrapper: #{wrap}" unless typeof handler is 'function' and handler.length is 1
	# 		mapper['_' + method] = mapper[method] = handler

	# fix route, add wrappers, and other handlers
	# _AjustRouteHandlers mapper, false

	# add static shortcut
	unless isDynamic
		app[STATIC_ROUTES][method + route] = mapper['~' + method] = [1, mapper, handler]
	# ends
	return


###*
 * Route wrappers
###
HTTP_SUPPORTED_METHODS.forEach (method)->
	method = method.toLowerCase()
	unless method is 'get'
		_defineProperty GridFW.prototype, method,
			value: (route, handler)-> @on method, ...arguments

# GET method
_defineProperty GridFW.prototype, 'get', value: (route, handler)->
	switch arguments.length
		when 2
			# apply controller
			if typeof handler is 'function'
				@on 'GET', route, handler
			# load static view or views
			else if typeof handler is 'string'
				@loadStaticViews route, handler # returns promise
				this
			# else
			else
				throw new Error 'Unsupported GET arguments'
		when 1
			@on 'GET', route
		else
			throw new Error 'Illegal GET arguments'
