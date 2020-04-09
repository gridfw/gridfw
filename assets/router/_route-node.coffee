###*
 * Create route node
###
_createRouteNode= ->
	# id
	route: null # String
	path: null	# array of nodes
	type: ROUTER_STATIC_NODE # Type of node: static, param, wildcard, ...
	param: null # param name to this node if not static
	# HTTP MAIN METHODS
	ALL:	null
	GET:	null
	HEAD:	null
	POST:	null
	PUT:	null
	PATCH:	null
	DELETE:	null
	# PARAMS
	params:	null	# parametred routes
	wildcards: null	# parametred wildcard
	wildcard: null	# General wildcard
	# Wrappers
	wrappers: null	# Array of wrappers
	onError: null # Array of error handlers
	# Static routes
	static:
		# Trailing slash
		'':	null

###*
 * Create main route node
###
_createMainRouteNode= ->
	node= do _createRouteNode
	node.static['']= node # reference same node
	node.route= '/'
	node.path= [node]
	return node