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
			# [_cacheLRU, node, param1Name, param1Value, ...]
			routeDescriptor = _resolveRoute this, method, rawPath
			routeNode = routeDescriptor[1]
			params = Object.create null
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
				params: value: params
			# resolve params
			if routeParamResolvers
				rawPI = 2
				rawPLen = routeDescriptor.length
				while rawPI < rawPLen
					paramName = routeDescriptor[rawPI]
					paramValue= routeDescriptor[++rawPI]
					++rawPI
					# resolve
					ref = routeParamResolvers[paramName]
					if ref and typeof ref[1] is 'function'
						params[paramName] = await ref[1] ctx, paramValue, <%= app.PATH_PARAM %>
					else
						params[paramName] = paramValue
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
		r = _resolveRoute this, method.toUpperCase(), route
		# return clone array to prevent user from changing it
		r.slice 0

