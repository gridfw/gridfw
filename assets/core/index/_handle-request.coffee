###* handle request ###
_handleRequest = (req, ctx)->
	try
		# settings
		settings = @s
		# request timeout
		# if  i = settings[<-%= settings.reqtimeout %->]
		# 	req.setTimeout i
		# 	req.connection.on 'timeout', ->
		# 		ctx.fatalError 'HANDLE-REQUEST', 'Request timeout'
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
					ctx.redirectPermanent rawPath
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
				# 	paramValue = await ref2[1] paramValue, <%= QUERY_PARAM %>, ctx
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
			rawQuery: value: queryParams
			query:
				value: queryParams
				configurable: on
		# add to request
		_defineProperties req,
			res: value: ctx
			ctx: value: ctx
			req: value: req
		# go to Step 2
		await _handleRequest2 this, ctx
	catch err
		ctx.fatalError 'HANDLE-REQUEST', err
		unless ctx.finished
			ctx.statusCode = 500
	finally
		# close the request if not yeat closed
		unless ctx.finished
			ctx.warn 'HANDLE-REQUEST', 'Request leaved open!'
			await ctx.end()
###* handle request: step 2 - common with mount app ###
_handleRequest2 = (app, ctx)->
	# execute handler wrappers
	if (wrappers = app.w) and wrappers.length
		nextIndex = 0
		next = =>
			wrapper = wrappers[nextIndex++]
			if wrapper
				return wrapper ctx, next
			else
				return _handleRequestCore app, ctx
		# execute request handling
		return next()
	else
		# execute request handling
		return _handleRequestCore app, ctx
###* wrappable request handler ###
_handleRequestCore = (app, ctx)->
	try
		# get route mapper
		# [_cacheLRU, node, controllerHandler, param1Name, param1Value, ...]
		console.log '--- resolve route:', ctx.method, ' ', ctx.path
		routeDescriptor = _resolveRoute app, ctx.method, ctx.path
		routeNode = routeDescriptor[1]
		controllerHandler = routeDescriptor[2]
		# resolve path params
		rawPI = ROUTER_PARAM_STATING_INDEX
		rawPLen = routeDescriptor.length
		routeParamResolvers = app.$
		if rawPI < rawPLen
			params = ctx.params
			while rawPI < rawPLen
				paramName = routeDescriptor[rawPI]
				paramValue= FastDecode routeDescriptor[++rawPI]
				++rawPI
				# resolve
				# ref = routeParamResolvers[paramName]
				# if ref and typeof ref[1] is 'function'
				params[paramName] = await routeParamResolvers[paramName][1] paramValue, <%= PATH_PARAM %>, ctx
				# else
				# 	params[paramName] = paramValue
		# resolve registred query params
		queryParams = ctx.query
		queryP = _create null
		_defineProperty ctx, 'query',
			value: queryP
			configurable: on
		for paramName of queryParams
			if ref2 = routeParamResolvers[paramName]
				paramValue = queryParams[paramName]
				if Array.isArray paramValue
					paramValue2 = []
					for v in paramValue
						paramValue2.push await ref2[1] v, <%= QUERY_PARAM %>, ctx
				else
					paramValue2= await ref2[1] paramValue, <%= QUERY_PARAM %>, ctx
				queryP[paramName]= paramValue2
			else
				queryP[paramName]= queryParams[paramName]
		# exec wrappers
		wrappers = routeNode.w
		if wrappers and wrappers.length
			nextIndex = 0
			next = ->
				wrapper = wrappers[nextIndex++]
				if wrapper
					return wrapper ctx, next
				else
					return controllerHandler ctx
			# execute request handling
			v = await next()
		else
			v = await controllerHandler ctx
		# execute post process
		await _handleRequestPostProcess ctx, v unless ctx.finished
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
			await _uncaughtRequestErrorHandler err, ctx, app
	return
###*
 * Handler post traitement
 * @usedBy request handler
 * @usedBy error handlers
###
_handleRequestPostProcess = (ctx, handlerResult)->
	if handlerResult in [undefined, ctx]
		# if a view is set
		if ctx.view
			return ctx.render ctx.view
	# when return string, it's view
	else if typeof handlerResult is 'string'
		return ctx.render handlerResult
	# else, it's json
	else
		return ctx.json handlerResult
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

