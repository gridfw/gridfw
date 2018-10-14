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
 * /dynamic/:param/:rest* # the rest of path will be stored in the param "rest"
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
					_createRouteNode this, method, route, c: handler
				else if typeof handler is 'object'
					_createRouteNode this, method, route, handler
				else
					throw new Error 'Illegal handler'
				# chain
				return this
			# .on 'GET', '/route'
			# create new node only if controller is specified, add handler to other routes otherwise
			when 2
				# do builder
				return new _RouteBuiler this, (node)=> _createRouteNode this, method, route, node
			else
				throw new Error '[app.on] Illegal arguments ' + JSON.stringify arguments
	###*
	 * Remove route
	 * @example
	 * .off('alll', '/route', hander) # remove this handler (as controller, preprocess, postprocess, errorHander, ...)
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
###
_createRouteNode = (app, method, route, nodeAttrs)->
	# flatten method
	if Array.isArray method
		for v in method
			_createRouteNode app, v, route, nodeAttrs
		return
	# check method
	throw new Error 'method expected string' unless typeof method is 'string'
	method = method.toUpperCase()
	throw new Error "Unknown http method [#{method}]" unless method is 'ALL' || method in HTTP_METHODS
	# flatten route
	if Array.isArray route
		for v in route
			_createRouteNode app, method, v, nodeAttrs
		return
	# check route
	throw new Error 'route expected string' unless typeof route is 'string'
	# prevent "?" symbol and multiple successive slashes
	throw new Error "Incorrect route: #{route}" if /^\?|\/\?[^:*]|\/\//.test route

	# settings
	settings = app.s
	# remove trailingSlash from route
	unless settings[<%= settings.trailingSlash %>]
		route = route.slice 0, -1 if route.endsWith '/'
	# route mast starts width "/"
	route = '/' + route unless route.startsWith '/'
	# make wildcard as param
	route = route.replace /\/([\w-]*\*)$/, '/:$1'
	# check if it is a static or dynamic route
	isDynamic = /\/:/.test route
	# route key
	routeKey = if isDynamic then route.replace(/\/:/g, '/?:') else route
	# get some already created node if exists
	allRoutes = app[ALL_ROUTES]
	ignoreCase = settings[<%= settings.routeIgnoreCase %>]
	# if dynamic route
	if isDynamic
		# if has controller, create the route
		if nodeAttrs.c
			# controller to all route
			# if route is '/*'
			# 	app.warn 'ROUTER', "[!] Add universal \"#{method} \\*\" will hide other routes"
			# 	routeMapper = allRoutes['/?*'] = app.m
			# else
			# lowercase and encode static parts
			route = route.replace /\/([^:][^\/]*)/g, (v)->
				v = v.toLowerCase() if ignoreCase
				encodeurl v
			# create mapper if not exists
			routeMapper = allRoutes[routeKey]
			unless routeMapper
				routeMapper= allRoutes[routeKey] = new RouteMapper app, route
			# add handlers to route
			app.debug 'ROUTER', 'Add dynamic route: ', method, route
			routeMapper.append method, nodeAttrs
			# map dynamic route
			mapper = _linkDynamicRoute app, route
			throw new Error "Dynamic mapper already set to: #{method} #{route}" if mapper.$$
			mapper.m = routeMapper
		# else add handler to any route or future route that matches
		else
			_registerRouteHandlers app, route, nodeAttrs
	# if static route, create node even no controller is specified
	else
		# convert route to lowercase unless case sensitive
		route = route.toLowerCase() unless ignoreCase
		# encode URL
		route = encodeurl route
		# create route mapper if not exists
		routeKey = route.replace /\/\?:/g, '/:'
		routeMapper = allRoutes[routeKey]
		unless routeMapper
			routeMapper= allRoutes[routeKey] =
			if route is '/' then app.m else new RouteMapper app, route
		# add handler to node
		routeMapper.append method, nodeAttrs
		# map as static route if has controller
		if nodeAttrs.c
			app.debug 'ROUTER', 'Add static route: ', method, routeKey
			app[STATIC_ROUTES][routeKey] = routeMapper
	# ends
	return


###*
 * link dynamic route
 * node['/static-part']
 * node.$['param-name']
 * node['*']['wildcard-paramName']
 * node.m = NodeMapper # link to node mapper
###
_linkDynamicRouteParamSet = new Set() # reuse this for performance purpose
_linkDynamicRoute = (app, route)->
	# if convert static parts to lower case
	convLowerCase = app.s[<%= settings.routeIgnoreCase %>]
	# check param names are not duplicated
	_linkDynamicRouteParamSet.clear()
	# exec
	currentNode = app[DYNAMIC_ROUTES]
	for part in route.split /(?=\/)/
		# if param
		if part.startsWith '/:'
			# is wildcard
			isWildcard = part.endsWith '*'
			# extract name
			if isWildcard
				part = part.slice 2, -1
				part = '*' unless part.length
			else
				part = part.substr 2
			# check param is correct
			throw new Error 'Could not use "__proto__" as param name' if part is '__proto__'
			unless ( isWildcard and part is '*' ) or ROUTE_PARAM_MATCH.test part
				throw new Error "Param names mast matche [a-zA-Z0-9_-]. Illegal param: [#{part}] at route: #{route}"
			# uniqueness of param name
			throw new Error "Dupplicated param name: #{part}" if _linkDynamicRouteParamSet.has part
			_linkDynamicRouteParamSet.add part
			# var
			k = if isWildcard then '*' else '$'
			currentNode[k] ?= Object.create null
			currentNode = currentNode[k][part] ?= Object.create null
		# if static part
		else
			part = part.toLowerCase() if convLowerCase
			currentNode = currentNode[part] ?= Object.create null
	# return
	currentNode

