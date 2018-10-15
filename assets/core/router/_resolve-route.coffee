###*
 * resolve routes
 * @param {GridFW} app - the app
 * @param {string} method - http method
 * @param {string} route - route path
###
_resolveRoute = do ->
	# route response
	# [0]: node
	# [1]: rawParams
	resolvedRoute = []
	paramStack  = [] # store params as [paramName, paramValue, ...]
	nextParamNodes	= [] # store condidate nodes as [node, level, paramName, paramlevel, ...]
	wildCardStack  = [] # store routes with wildcard as [node, level, paramName, paramLevel, ...]
	# 404 Error node (enable caching)
	err404Node =
		c: ->
			throw ERROR_404 
	# resolve dynamic route
	_resolveDynamicRoute = (app, method, route, ignoreCase)->
		console.log '::::: Resolve dynamic route>> ', route
		# init
		currentNode = app[DYNAMIC_ROUTES]
		paramStack.length = 0
		wildCardStack.length = 0
		nextParamNodes.length = 0
		# 
		parts = route.split '/'
		i = 0
		paramIdx = 0
		len = parts.length
		routeNode = null # final resolved route node
		# go to param level
		_goToParamLevel = =>
			console.log '-------- GO TO NEXT NODE --------'
			paramIdx = nextParamNodes.pop()
			pName = nextParamNodes.pop()
			i = nextParamNodes.pop()
			currentNode = nextParamNodes.pop()
			# param stack
			paramStack.splice paramIdx
			# paramIdx = paramStack.length
			paramStack.push pName, parts[i]
			paramIdx = paramStack.length
			# go to next element
			++i
		# check params with regex
		_paramRegexCheck = (currentNode, paramStackLen)->
			node = null
			if ( routeMapper = currentNode.m ) and
			( node = routeMapper[method] or (method is 'HEAD' and routeMapper.GET) or routeMapper.ALL )
				# paramStackLen = paramStack.length
				nodeParams = node.$
				idx = 0
				while idx < paramStackLen
					# get param info
					paramName = paramStack[idx]
					paramValue = paramStack[++idx]
					++idx
					# check param with regex
					t = nodeParams[paramName]
					if t and not t[0].test paramValue
						node = null
						break # test fails
			node
		# loop
		loop
			# seek for path
			while i < len
				part = parts[i]
				currentPosition = i
				++i
				# ignore empty parts (case of first, last and mutiple slashes)
				continue unless part
				# ignore case for static part
				staticPart = '/' + part
				staticPart = staticPart.toLowerCase() if ignoreCase is 1
				# check if static part
				node = currentNode[staticPart]
				if node
					currentNode = node
					continue
				# add params
				if currentNode.$
					for k, v of currentNode.$
						nextParamNodes.push v, currentPosition, k, paramIdx
				# add wildcard params
				if currentNode['*']
					for k, v of currentNode['*']
						lst = paramStack.slice 0
						lst.push k
						wildCardStack.push v, currentPosition, lst
				# go to next node
				if nextParamNodes.length
					_goToParamLevel()
				else
					currentNode = null # fail to get route
					break
			# check params with regexes if resolved
			if currentNode and routeNode = _paramRegexCheck currentNode, paramStack.length
				break # break loop if regexes succeed
			# if regex test fails or no node resolved, check an other track
			# go to next param track
			if nextParamNodes.length
				_goToParamLevel()
			# use a wild card path
			else if wildCardStack.length
				console.log '----- look for longest wildcard path'
				# get longest that matches regexes
				idx = 0
				len = wildCardStack.length
				longestLevel = 0 # store longest level
				longestParamLevel = 0 # store longest level
				while idx < len
					console.log '--- wild loop'
					# resolve values
					currentNode	= wildCardStack[idx]
					i			= wildCardStack[++idx]
					pStack	= wildCardStack[++idx]
					++idx
					# continue if this level less than the last resolved one
					if i <= longestLevel
						continue
					# use regex
					if currentNode and node = _paramRegexCheck currentNode, i
						longestLevel = i
						longestParamStack = pStack
						routeNode = node
						break # break loop if regexes succeed
				# concat last params
				if routeNode
					paramStack = longestParamStack
					paramStack.push parts.slice(longestLevel).join '/'
				# break loop
				break
			# 404 not found
			else
				routeNode = null
				break
		# return node
		if routeNode
			console.log '--- route resolved'
			resolvedRoute[0] = routeNode
			# save params
			rawParams = resolvedRoute[1]
			len = paramStack.length
			i = 0
			while i < len
				rawParams[ paramStack[i] ] = paramStack[++i]
				++i
		else
			console.log '--- route not found'
			resolvedRoute[0] = err404Node
		# end
		return
	# return resolver
	(app, method, route)->
		# node
		resolvedRoute[0] = err404Node
		# params
		rawParams = resolvedRoute[1] = Object.create null
		# root node
		if route is '/'
			node = app.m[method]
			if node or ( method is 'HEAD' and (node = app.m.GET)) or (node = app.m.ALL)
				resolvedRoute[0] = node
		# child node
		else
			settings = app.s
			### Remove repeated slashes ###
			# route = route.replace /\/{2,}/g, '/'
			### case sensitive ###
			ignoreCase = settings[<%= settings.routeIgnoreCase %>]
			# ignore case
			if ignoreCase is 1
				route = staticRoute = route.toLowerCase()
			# ignore static part case only (do not change param values)
			else if ignoreCase is on
				staticRoute = route.toLowerCase()
			# case sensitive
			else
				staticRoute = route

			### get route if static ###
			routeMapper = app[STATIC_ROUTES][staticRoute]
			### when not static route, look for dynamic one ###
			if routeMapper and (node = routeMapper[method] or (method is 'HEAD' and (node = routeMapper.GET)) or (node=routeMapper.ALL) )
				resolvedRoute[0] = node
			# cache logic
			# <!> enable this cache!!!
			# else if (node = app[CACHED_ROUTES][route])
			# 	resolvedRoute[0] = node[0] # node
			# 	resolvedRoute[1] = node[1] # params
			# 	++node[2] # inc access count (to remove less access)
			# resolve dynamic route
			else
				_resolveDynamicRoute app, method, route, ignoreCase
		# return resolved route
		resolvedRoute
