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
	throw new Error 'Illegal arguments' unless arguments.length is 3
	@_add methodName, route, handler, [@_routes]
	this # chain
_add: (methodName, route, handler, currentNodes)->
	# Flatten methodName
	if _isArray methodName
		@_add el, route, handler, currentNodes for el in methodName
		return
	# Flatten route
	if _isArray route
		@_add methodName, el, handler, currentNodes for el in route
		return
	# Logic
	throw new Error "Expected route to be string" unless typeof route is 'string'
	throw new Error "Expected http method to be string" unless typeof methodName is 'string'
	methodName= methodName.toUpperCase()
	throw new Error "Illegal HTTP method: #{methodName}. Expected: #{HTTP_METHODS.join ', '}, ALL" unless (methodName in HTTP_METHODS) or methodName is 'ALL'
	throw new Error "handler expected: async function(ctx){...}. received: #{handler}" unless (typeof handler is 'function') and (handler.length in [1,0])
	# Resolve route
	nodes= _resolveTreeNode this, route, currentNodes
	switch methodName
		when 'HEAD'
			for node in nodes
				throw new Error "Controller <HTTP.HEAD> already set at: #{node.route}" if node.HEAD and node.HEAD isnt node.GET
				node.HEAD= handler
		when 'GET'
			for node in nodes
				throw new Error "Controller <HTTP.GET> already set at: #{node.route}" if node.GET
				node.GET= handler
				node.HEAD?= handler
		else
			for node in nodes
				throw new Error "Controller <HTTP.#{methodName}> already set at: #{node.route}" if node[methodName]
				node[methodName]= handler
	# reload caches
	@clearRouterCache()
	return
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
			nodes= _resolveRouteNodes this, route, [@_routes]
			for node in nodes
				if (len is 2) or (node[methodName] is handler)
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
