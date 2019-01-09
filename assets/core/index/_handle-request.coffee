###* handle request ###
_handleRequest = (req, ctx)->
	try
		# settings
		settings = @s
		# path
		url = req.url
		i = url.indexOf '?'
		if i is -1
			rawPath = url
			rawUrlQuery = null
		else
			rawPath = url.substr 0, i
			rawUrlQuery = url.substr i + 1
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
		# resolve query params
		queryParams = _create null
		if rawUrlQuery
			ref = @queryParser rawUrlQuery
			len = ref.length
			k = 0
			while k < len
				# get param name and value
				paramName = ref[k]
				paramValue= ref[++k]
				++k
				# check param name
				if paramName is '__proto__'
					ctx.warn 'query-parser', 'Received query param with illegal name: __proto__'
					paramName = '&__proto__'
				# resolve if registred param
				# if ref2 = routeParamResolvers[paramName]
				# 	paramValue = await ref2[1] paramValue, <%= app.QUERY_PARAM %>, ctx
				# groupement
				if Reflect.has queryParams, paramName
					ref2 = queryParams[paramName]
					if Array.isArray ref2
						ref2.push paramValue
					else
						queryParams[paramName] = [ref2, paramValue]
				else
					queryParams[paramName] = paramValue
		# basic ctx attributes
		_defineProperties ctx,
			req: value: req
			res: value: ctx
			# url
			method: value: req.method
			url:value: url
			path: # changeable by third middleware (like i18n or URL rewriter)
				value: rawPath
				writable: on
				configurable: on
			# params
			params: value: _create null
			query: value: queryParams
		# add to request
		_defineProperties req,
			res: value: ctx
			ctx: value: ctx
			req: value: req
		# ...
	catch e
		# ...
	
###* wrappable request handler ###
_handleRequestCore = (ctx)->
	try
		# settings
		settings = @s
		# path
		# url = req.url
		# i = url.indexOf '?'
		# if i is -1
		# 	rawPath = url
		# 	rawUrlQuery = null
		# else
		# 	rawPath = url.substr 0, i
		# 	rawUrlQuery = url.substr i + 1
		# # basic ctx attributes
		# _defineProperties ctx,
		# 	req: value: req
		# 	res: value: ctx
		# 	# url
		# 	method: value: method
		# 	url: value: req.url
		# # add to request
		# _defineProperties req,
		# 	res: value: ctx
		# 	ctx: value: ctx
		# 	req: value: req
		# get route mapper
		# [_cacheLRU, node, param1Name, param1Value, ...]
		routeDescriptor = _resolveRoute this, ctx.method, ctx.path
		routeNode = routeDescriptor[1]
		controllerHandler = routeDescriptor[2]
		# params = _create null
		# parse query params
		# queryParams = _create null
		# add context attributes
		# _defineProperties ctx,
		# 	# url
		# 	# path: value: rawPath
		# 	query: value: queryParams
		# 	# params
		# 	params: value: params
		# resolve path params
		rawPI = ROUTER_PARAM_STATING_INDEX
		rawPLen = routeDescriptor.length
		routeParamResolvers = @$
		if rawPI < rawPLen
			params = ctx.params
			while rawPI < rawPLen
				paramName = routeDescriptor[rawPI]
				paramValue= fastDecode routeDescriptor[++rawPI]
				++rawPI
				# resolve
				# ref = routeParamResolvers[paramName]
				# if ref and typeof ref[1] is 'function'
				params[paramName] = await routeParamResolvers[paramName][1] paramValue, <%= app.PATH_PARAM %>, ctx
				# else
				# 	params[paramName] = paramValue
		# resolve registred query params
		queryParams = ctx.query
		for paramName of queryParams
			if ref2 = routeParamResolvers[paramName]
				paramValue = queryParams[paramName]
				if Array.isArray paramValue
					for v, k in paramValue
						paramValue[k] = await ref2[1] v, <%= app.QUERY_PARAM %>, ctx
				else
					queryParams[paramName] = await ref2[1] paramValue, <%= app.QUERY_PARAM %>, ctx
		# execute middlewares
		if routeNode.m
			for handler in routeNode.m
				await handler ctx
		# execute filters
		# if routeNode.f
		# 	for handler in routeNode.f
		# 		await handler ctx
		# execute Controller
		v = await controllerHandler ctx
		unless ctx.finished
			if v in [undefined, ctx]
				# if a view is set
				if ctx.view
					await ctx.render()
			else
				await ctx.render v
				#TODO
		# execute post processes
		# if ctx.p
		# 	for handler in routeNode.p
		# 		await handler ctx
	catch err
		# excute user defined error handlers
		if routeNode?.e
			for errHandler in routeNode.e
				try
					await errHandler err, ctx
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
			ctx.warn 'HANDLE-REQUEST', 'Request leaved open!'
			await ctx.end()
	return
###*
 * Handle incomming request
###
_defineProperties GridFW.prototype,
	###*
	 * Handle incomming request
	###
	handle: value: _handleRequest
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
		r = _resolveRoute this, method.toUpperCase(), route
		# return clone array to prevent user from changing it
		r.slice 0

