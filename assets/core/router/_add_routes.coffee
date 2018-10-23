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
Object.defineProperties GridFW.prototype,
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
	 * 		.use(middleware) # use a middleware
	 * 		#Add filters
	 * 		.filter(function(ctx){})
	 * 		.filter(Filters.isAuthenticated)
	 * 		# user promise like processing
	 * 		.then(handler)
	 * 		.then(handler2)
	 * 		.catch(err => {})
	 * 		.then(handler3)
	 * 		.finally(handler)
	 * 		.then(handler)
	 * 		# add param handler (we suggest to use global params as possible to avoid complexe code)
	 * 		.param('paramName', function(ctx){})
	 ****
	 * Add Global error handling and post process
	 * <!> do not confuse with promise like expression
	 * there is no "then" method
	 ****
	 * Route.on('GET', 'path/to/resource')
	 * 		.catch(err=>{}) # Global error check
	 * 		.finally(ctx =>{}) # post process
	 * 		
	###
	on: value: (method, route, handler)->
		# clear route cache
		@[CACHED_ROUTES] = Object.create null if @[IS_LOADED]
		# Add handlers
		switch arguments.length
			# .on 'GET', '/route', handler
			when 3
				if typeof handler is 'function'
					throw new Error 'handler could take only one argument' if handler.length > 1
					_createRouteNode this, method, route, handler
				else
					throw new Error 'Illegal handler'
				# chain
				return this
			# .on 'GET', '/route'
			# create new node only if controller is specified, add handler to other routes otherwise
			when 2
				# do builder
				return new _RouteBuiler this, (handler, descrp)=> _createRouteNode this, method, route, handler, descrp
			else
				throw new Error '[app.on] Illegal arguments ' + JSON.stringify arguments
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
		# exec
		# switch arguments.length
		# 	# off(method, route)
		# 	when 2:
		# 		if method
		#TODO


###*
 * Create route node or add handlers to other routes
 * @optional @param {object} descrp - other optional params
###
_createRouteNode = (app, method, route, handler, descrp)->
	# flatten method
	if Array.isArray method
		for v in method
			_createRouteNode app, v, route, handler, descrp
		return
	# check method
	throw new Error 'method expected string' unless typeof method is 'string'
	method = method.toUpperCase()
	throw new Error "Unknown http method [#{method}]" unless method is 'ALL' || method in HTTP_METHODS
	# flatten route
	if Array.isArray route
		for v in route
			_createRouteNode app, method, v, handler, descrp
		return
	# check route
	assetRoute route
	
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
		route = route.replace /\/([^?][^\/]*)/g, (v)->
			v = v.toLowerCase() if ignoreCase
			encodeurl v
	else
		route = route.toLowerCase() if ignoreCase
		route = encodeurl route
	# get or create route tree
	app.debug 'RTER', "Map the controller to #{method} #{originalRoute}"
	mapper = _createRouteTree app, route
	# add controller
	if handler
		throw new Error 'Controller mast be function' unless typeof handler is 'function'
		throw new Error "Route has allready a controller: #{method} #{originalRoute}" if mapper[method]
		mapper[method] = handler
		mapper['_' + method] = handler

	# optional operations
	if descrp
		# wrappers
		if descrp.wrappers
			app.info 'RTER', "Wrap controller at: #{method} #{originalRoute}"
			handler = mapper[method]
			throw new Error 'No controller to wrap at: #{method} #{originalRoute}' unless mp
			for wrap in descrp.wrappers
				handler = wrap handler
				throw new Error "Illegal wrapper response! wrapper: #{wrap}" unless typeof handler is 'function' and handler.length is 1
			mapper['_' + method] = mapper[method] = handler

	# fix route, add wrappers, and other handlers
	_AjustRouteHandlers mapper, false

	# add static shortcut
	unless isDynamic
		app.debug 'RTER', "Create static shortcut: #{method} #{originalRoute}"
		app[STATIC_ROUTES][method + route] = [1, mapper, handler]
	# ends
	return


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