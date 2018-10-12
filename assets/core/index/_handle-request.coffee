###*
 * Handle incomming request
###
Object.defineProperties GridFW.prototype,
	###*
	 * Handle incomming request
	###
	handle: value: (req, ctx)->
		try
			# settings
			settings = @s
			# path
			url = req.url
			method = req.method
			i = url.indexOf '?'
			if i is -1
				rawPath = url
				rawUrlQuery = null
			else
				rawPath = url.substr 0, i
				rawUrlQuery = url.substr i + 1
			# basic ctx attributes
			Object.defineProperties ctx,
				req: value: req
				res: value: ctx
				# url
				method: value: method
				url: value: req.url
			# add to request
			Object.defineProperties req,
				res: value: ctx
				ctx: value: ctx
				req: value: req
			# trailing slash
			unless rawPath is '/'
				ref= settings[<%= settings.trailingSlash %>]
				# do redirect
				if ref is 0
					if rawPath.endsWith '/'
						rawPath = rawPath.slice 0, -1
						rawPath = rawPath.concat '?', rawUrlQuery if rawUrlQuery
						ctx.permanentRedirect rawPath
						return
				else if ref is off
					rawPath = rawPath.slice 0, -1 if rawPath.endsWith '/'
			# get route mapper
			routeDescriptor = _resolveRoute this, method, rawPath
			routeNode= routeDescriptor[0]
			rawParams = routeDescriptor[1] || EMPTY_OBJ
			params = Object.create rawParams
			routeParamResolvers = routeNode.$
			# parse query params
			rawUrlQuery = @queryParser rawUrlQuery
			queryParams = Object.create rawUrlQuery
			# add context attributes
			Object.defineProperties ctx,
				# url
				path: value: rawPath
				rawQuery: value: rawUrlQuery
				query: value: queryParams
				# params
				rawParams: value: rawParams
				params: value: params
			# resolve params
			if rawParams and routeParamResolvers
				for k, v of rawParams
					ref = routeParamResolvers[k]
					if ref and typeof ref[1] is 'function'
						params[k] = await ref[1] ctx, v, <%= app.PATH_PARAM %>
			# resolve query params
			if rawUrlQuery and routeParamResolvers
				for k, v of queryParams
					ref = routeParamResolvers[k]
					if ref and typeof ref[1] is 'function'
						queryParams[k] = await ref[1] ctx, v, <%= app.QUERY_PARAM %>
			# execute middlewares
			if routeNode.m
				for handler in routeNode.m
					await handler ctx
			# execute filters
			if routeNode.f
				for handler in routeNode.f
					await handler ctx
			# execute Controller
			v = await routeNode.c ctx
			unless ctx.finished
				if v in [undefined, ctx]
					# if a view is set
					if ctx.view
						await ctx.render()
				else
					await ctx.render v
			# execute post processes
			if ctx.p
				for handler in routeNode.p
					await handler ctx
		catch err
			# excute user defined error handlers
			if routeNode?.e
				for handler in routeNode.e
					try
						await handler err, ctx, this
						err = null
						break
					catch e
						err = e
			if err
				await _uncaughtRequestErrorHandler err, ctx, this
				.catch (err)=> @fatalError 'HANDLE-REQUEST', err
		finally
			# close the request if not yeat closed
			unless ctx.finished
				ctx.warn 'HANDLE-REQUEST', 'Request leaved inclose!'
				await ctx.end()
		return

	###*
	 * get route Mapper and resolve params
	###
	find: value: (method, route)->
		throw new Error 'Illegal arguments' unless arguments.length is 2
		throw new Error 'Method expected string' unless typeof method is 'string'
		throw new Error 'Route expected string' unless typeof route is 'string'
		route = '/' + route unless route.startsWith '/'
		### trailing slash ###
		unless route is '/' or @s[<%= settings.trailingSlash %>]
			route = route.slice 0, -1 if route.endsWith '/'
		_resolveRoute this, method.toUpperCase(), route

###*
 * resolve route
 * @return [routeMapper, resolvedParams]
###
# for performance perpose, we reuse those arrays ( hold on, js is unithread ;) )
_resolveRouteA1 = [] 
_resolveRouteA2 = []
# resolver
_resolveRoute= (app, method, route)->
	# root node
	if route is '/'
		node = app.m[method]
		unless node or ( method is 'HEAD' and (node = app.m.GET)) or (node = app.m.ALL)
			throw ERROR_404
		routeMapper = [node, null]
	# child node
	else
		settings = app.s
		### Remove repeated slashes ###
		route = route.replace /\/{2,}/g, '/'
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
			routeMapper = [node, null]
		else
			#TODO add cache for dynamic routes and check if it upgride performance

			# check for route
			_resolveRouteA2.length = 0
			_resolveRouteA2.push [ app[DYNAMIC_ROUTES], Object.create null ]
			for part in route.substr(1).split '/'
				# ignore case for static part
				staticPart = '/' + part
				staticPart = staticPart.toLowerCase() if ignoreCase is 1
				# invert arrays
				[_resolveRouteA1, _resolveRouteA2] = [_resolveRouteA2, _resolveRouteA1]
				_resolveRouteA2.length = 0
				# go through current step resolved nodes
				for nodeArr in _resolveRouteA1
					# check if static part
					node = nodeArr[0]
					nextNode = node[staticPart]
					if nextNode
						nodeArr[0] = nextNode
						_resolveRouteA2.push nodeArr
					# check for dynamic part
					else if node.$
						ref = node.$
						kies = Object.keys ref
						if kies.length is 1
							k = kies[0]
							nodeArr[0] = ref[k]
							nodeArr[1][k] = part
							_resolveRouteA2.push nodeArr
						else
							for k,v of node.$
								p = Object.create nodeArr[1]
								p[k] = part
								_resolveRouteA2.push [v, p]
					# check for universal params matchers
					
				# break if no more nodes
				unless _resolveRouteA2.length
					throw ERROR_404
			# filter nodes missing method and using params regexes
			# [node, params]
			_resolveRouteA1.length = 0
			`R: //`
			for nodeArr in _resolveRouteA2
				routeMapper = nodeArr[0].$$
				if routeMapper
					# get Method
					node = routeMapper[method] or (method is 'HEAD' and routeMapper.GET) or routeMapper.ALL
					continue unless node
					# go through params
					for k, v of nodeArr[1]
						p = node.$[k]
						if p and not p[0].test v
							`continue R`
					nodeArr[0] = node
					_resolveRouteA1.push nodeArr
			# throw 404 if all nodes are filtered
			throw ERROR_404 unless _resolveRouteA1.length
			# throw errors if there is more then one node resolved
			if _resolveRouteA1.length > 1
				throw new GError 500,
					"Multiple controllers matched the request: #{route}",
					nodes: _resolveRouteA1.slice 0
			# resolved node
			routeMapper = _resolveRouteA1[0]
			#TODO put in route cache
	# return resolved node
	# [nodeMapper, paramMap]
	routeMapper

					

