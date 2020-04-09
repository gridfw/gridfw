###*
 * Http wrappers
###
get:	(route, handler)-> @add 'GET', route, handler
head:	(route, handler)-> @add 'HEAD', route, handler
post:	(route, handler)-> @add 'POST', route, handler
###*
 * Add http method
 * @example
 * 	app.add('GET', '/a/b', function(ctx){...})
 * 	app.add(app2) # Add all routes from and other app
 * 	app.add('/a/b', app2) # Add all routes from and other app under route "/a/b/"
###
add: (methodName, route, handler)->
	try
		throw 'Illegal arguments' unless arguments.length is 3
		if _isArray methodName
			for el in methodName
				@add el, route, handler
			return this # chain
		if _isArray route
			for el in route
				@add methodName, el, handler
			return this # chain
		# check handler
		throw "handler expected: async function(ctx){...}. received: #{handler}" unless (typeof handler is 'function') and (handler.length in [1,0])
		# check methodName
		throw "Usupported http method: #{methodName}. Accepted are: #{HTTP_METHODS.join ', '}, ALL" unless (typeof methodName is 'string') and (((methodName= methodName.toUpperCase()) in HTTP_METHODS) or methodName is 'all')
		# Resolve route
		node= _resolveTreeNode this, route
		node[methodName]= handler
		# Link HEAD method to GET when missing
		node.HEAD= handler if (methodName is 'GET') and not node.HEAD
		# reload caches
		@clearRouterCache()
		this # chain
	catch err
		err= new Error "Add route>> #{err}\n#{route}" if typeof err is 'string'
		throw err
###*
 * Remove http route
 * @example
 * app.remove('/route')					# Romove route and subroutes
 * app.remove('get', '/route') 			# Remove get method of this route
 * app.remove('get', '/route', handler)	# Remove GET method if hand this handler
###
remove: (methodName, route, handler)->
	try
		len= arguments.length
		# Remove all route and subroutes
		if len is 1
			#TODO
			throw 'inimplemented: regenerate tree'
		# remove method
		else if len in [2, 3]
			result= _resolveRouteNodes this, route
			node= result.node
			if result.found and ((len is 2) or (node[methodName] is handler))
				# remvoe HEAD handler if reflect of GET handler
				node.HEAD= null if methodName is 'GET' and node.GET is node.HEAD
				# remove handler
				node[methodName]= null
		# Illegal
		else
			throw 'Illegal arguments'
		this # chain
	catch err
		err= "Remove route>> #{err}" if typeof err is 'string'
		throw err
	
###*
 * Add route using builder
###
route: (route)-> new RouteBuilder this, route

###*
 * Clear router cache
###
clearRouterCache: ->
	@_routerCache.clear()
	this # chain