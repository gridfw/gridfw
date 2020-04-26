###*
 * Route tree system
 * @see  _tree.doc.coffee file for internal architecture
 * app.routes= []
###

ROUTER_STATIC_NODE= 0
ROUTER_PARAM_NODE= 1
ROUTER_WILDCARD_PARAM_NODE= 2
ROUTER_WILDCARD_NODE= 3

###*
 * Resolve or create node inside parametred table
 * @param {String} paramName - Param name
 * @param {Array} arr - [paramName, regex, node, paramName, regex, node, ...]
 * @private
###
_resolveNodeInArray= (part, paramMap, arr, upsert)->
	paramName= part.slice 1
	throw "Please use \"app.param(...)\" method to define path-parameter: #{paramName}" unless _has paramMap, paramName
	paramRegex= paramMap[paramName][0]
	len= arr.length
	i= 0
	while i<len
		return arr[i+2] if arr[i+1] is paramName
		i+= 3
	if upsert
		node= do _createRouteNode
		node.param= paramName
		arr.push paramRegex, paramName, node
	return node


###* RESOLVE TREE NODE ###
ROUTE_ILLEGAL_PATH_REGEX= /#|[^\/]\?/
_resolveTreeNode= (app, path)->
	# Check path
	throw 'Expected path to be string' unless typeof path is 'string'
	throw "Illegal path: #{path}" if ROUTE_ILLEGAL_PATH_REGEX.test(path)
	settings= app.settings
	path= path.trim()
	# path= '/'+path unless path.startsWith('/')
	routerIgnoreCase= settings.routerIgnoreCase
	# path= path.toLowerCase() if settings.routerIgnoreCase
	# start
	currentNode= app._routes
	avoidTrailingSlash= not settings.trailingSlash
	paramMap= app._params
	parts= path.split '/'
	partsLen= parts.length
	nodePath= []
	paramSet= new Set() # check params are not repeated
	for part,i in parts
		# wild card
		if part is '*'
			throw "Illegal use of wildcard: #{path}" unless i+1 is partsLen
			node= currentNode.wildcard ?= do _createRouteNode
			node.type= ROUTER_WILDCARD_NODE
			node.param= '*'
		# parametred wildcard
		else if part.startsWith('*')
			throw "Illegal use of wildcard: #{path}" unless i+1 is partsLen
			currentNode.wildcards?= []
			node= _resolveNodeInArray part, paramMap, currentNode.wildcards, yes
			node.type= ROUTER_WILDCARD_PARAM_NODE
		# parametred node
		else if part.startsWith(':')
			currentNode.params?= []
			node= _resolveNodeInArray part, paramMap, currentNode.params, yes
			node.type= ROUTER_PARAM_NODE
		# static node
		else
			part= part.slice(1) if part.startsWith('?') # escaped static part
			part= part.toLowerCase() if routerIgnoreCase
			node= currentNode.static[part] ?= do _createRouteNode
			node.type= ROUTER_STATIC_NODE
		# Check params not repeated
		if vl= node.param
			throw "Repeated param [#{vl}] in route: #{path}" if paramSet.has vl
			paramSet.add vl
		# Avoid trailing slash and multiple slashes
		node.static['']= node if avoidTrailingSlash # Avoid trailing slash and multiple slashes
		# stack
		nodePath.push node
		unless node.path
			node.path?= nodePath.slice(0)
			node.route= parts.slice(0, i+1).join('/')
		# next
		currentNode= node
	return currentNode

# GET all nodes in a route
_resolveRouteNodes= (app, path)->
	# Check path
	throw 'Expected path to be string' unless typeof path is 'string'
	throw "Illegal path: #{path}" if ROUTE_ILLEGAL_PATH_REGEX.test(path)
	path= path.trim()
	# path= '/'+path unless path.startsWith('/')
	currentNode= app._routes
	paramMap= app._params
	routerIgnoreCase= app.settings.routerIgnoreCase
	# parts= path.split /(?=\/)/
	parts= path.split '/'
	partsLen= parts.length
	nodes= [currentNode]
	found= yes
	for part,i in parts
		# wild card
		if part is '*'
			node= currentNode.wildcard
		# parametred wildcard
		else if part.startsWith('*') and currentNode.wildcards
			node= _resolveNodeInArray part, paramMap, currentNode.wildcards, no
		# parametred node
		else if part.startsWith(':')
			currentNode.params?= []
			node= _resolveNodeInArray part, paramMap, currentNode.params, no
		# static node
		else
			part= part.slice(1) if part.startsWith('?') # escaped static part
			part= part.toLowerCase() if routerIgnoreCase
			node= currentNode.static[part]
		# finish
		if node
			# next
			currentNode= node
			nodes.push node
		else
			found= no
			break
	return
		found: found
		nodes: nodes
		node: currentNode


###*
 * ERROR wrappers
###
ROUTER_404= -> throw 404
ROUTER_500= -> throw 500
###*
 * Resolve route path using DFS algorithm
 * @return {node, wrappers, errorHandlers: [], params:[params, paramValue, ...]}
###
_resolveRouterPath= (app, method, path)->
	currentNode= app._routes
	paramMap= app._params
	path= path.toLowerCase() if app.settings.routerIgnoreCase
	# result
	wrappers= []
	onErrorHandlers= []
	# result
	result=
		status:			404
		node:			null
		handler:		ROUTER_404
		params:			[]
		wrappers:		[]
		errorHandlers:	[]
	try
		# DFS init
		###*
		 * Store node metadata
		 * [paramIndex, nodeType, dept]
		 * nodeType:
		 * 		0: Static
		 * 		1: params
		 * 		2: wildcard param
		 * 		3: wildcard
		 * paramIndex: Current Index of node when: params or wildcard params
		 * dept: Path dept
		###
		metadataStack= [0,0,0] # [NodeType(0:static)]
		###* Store node stack ###
		nodeStack= [currentNode]
		# routeStack= [] # Store route path nodes

		# BEGIN
		parts= path.slice(1).split '/'
		partsLen= parts.length
		maxLoops= ROUTER_MAX_LOOP # max loops
		maxLoopsI= 0 # Inc is faster than dec
		while nodeStack.length
			# prevent server freez
			throw new Error "Router>> Seeking exceeds #{maxLoops}" if ++maxLoopsI > maxLoops
			# node
			currentNode= nodeStack.pop()
			# metadata
			dept=		metadataStack.pop()
			nodeType=	metadataStack.pop()
			nodeIndex=	metadataStack.pop()
			# track
			# routeStack.splice dept, Infinity, currentNode
			# path part
			part= parts[dept]
			# switch nodetype
			switch nodeType
				when ROUTER_STATIC_NODE # Static
					# add alts
					if currentNode.wildcard
						nodeStack.push currentNode
						metadataStack.push 0, ROUTER_WILDCARD_NODE, dept
					if currentNode.wildcards
						nodeStack.push currentNode
						metadataStack.push 0, ROUTER_WILDCARD_PARAM_NODE, dept
					if currentNode.params
						nodeStack.push currentNode
						metadataStack.push 0, ROUTER_PARAM_NODE, dept
					# check for static node
					if node= currentNode.static[part]
						currentNode= node
						++dept
						if dept < partsLen
							nodeStack.push currentNode
							metadataStack.push 0, ROUTER_STATIC_NODE, dept
					#TODO exit when end
				when ROUTER_PARAM_NODE # path param
					params= currentNode.params
					len= params.length
					while nodeIndex<len
						if params[nodeIndex].test part
							# save current index
							nodeStack.push currentNode
							metadataStack.push (nodeIndex+3), ROUTER_PARAM_NODE, dept
							# go to sub route
							currentNode= params[nodeIndex+2]
							++dept
							if dept < partsLen
								nodeStack.push currentNode
								metadataStack.push nodeIndex, ROUTER_STATIC_NODE, dept
							break
						nodeIndex+= 3
				when ROUTER_WILDCARD_PARAM_NODE # wildcard param
					params= currentNode.wildcards
					len= params.length
					pathEnd= parts.slice(dept).join('/')
					while nodeIndex<len
						if params[nodeIndex].test pathEnd
							# go to sub route
							currentNode= params[nodeIndex+2]
							dept= partsLen
							break
						nodeIndex+= 3
				when ROUTER_WILDCARD_NODE # wildcard
					currentNode= currentNode.wildcard
					dept= partsLen
				else
					throw "Unexpected error: Illegal nodeType #{nodeType}"
			# Check if found
			if (dept is partsLen) and (handler= currentNode[method] or currentNode.ALL)
				result.status= 200
				result.node= currentNode
				result.handler= handler
				# Load wrappers and error handlers
				wrappers= result.wrappers
				errHandlers= result.errorHandlers
				paramArr= result.params
				j=-1
				for node in currentNode.path
					# wrappers
					if arr= node.wrappers
						wrappers.push el for el in arr
					# error handlers
					if arr= node.onError
						errHandlers.push el for el in arr
					# params
					switch node.type
						when ROUTER_PARAM_NODE
							paramArr.push node.param, parts[j]
						when ROUTER_WILDCARD_PARAM_NODE, ROUTER_WILDCARD_NODE
							paramArr.push node.param, parts.slice(j).join('/')
					# next
					++j
				break
	catch err
		err= new Error "ROUTER>> #{err}" if typeof err is 'string'
		app.fatalError 'ROUTER', err
		result.status= 500 # Internal error
		result.handler= ROUTER_500
	return result

	