###*
 * Build mutlipe http methods on a route
 * @example
 * 		new RouteBuilder(app, 'route')
 * 		new RouteBuilder(app, ['route1', 'route2', ...])
###
class RouteBuilder
	constructor: (app, route)->
		@_app= app
		# Get currentNodes
		rootNodes= [app._routes]
		if typeof route is 'string'
			currentNodes= _resolveTreeNode app, route, rootNodes
		else if _isArray route
			currentNodes= []
			for el in route
				throw new Error "Illegal route" unless typeof el is 'string'
				result= _resolveTreeNode app, el, rootNodes
				currentNodes.push node for node in result when node not in currentNodes
		else
			throw new Error 'Illegal route'
		@_currentNodes= currentNodes
		return
	# HTTP methods
	get: (route, handler)->
		throw new Error "Expected two arguments" unless arguments.length is 2
		@add 'GET', route, handler
	head: (route, handler)->
		throw new Error "Expected two arguments" unless arguments.length is 2
		@add 'HEAD', route, handler
	post: (route, handler)->
		throw new Error "Expected two arguments" unless arguments.length is 2
		@add 'POST', route, handler
	add: (methodName, route, handler)->
		throw new Error "Expected three arguments" unless arguments.length is 3
		@_app._add methodName, route, handler, @_currentNodes
		this # chain
	wrap: (route, handler)->
		throw new Error "Expected two arguments" unless arguments.length is 2
		@_app._wrap route, handler, @_currentNodes
		return
