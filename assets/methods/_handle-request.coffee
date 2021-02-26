###*
 * Handler request
###
handle: do ->
	# Handle request final step
	_handleRequest= (app, ctx)->
		try
			# Resolve route from Cache
			path= ctx.pathname
			cachePathKey= "#{ctx.method} #{path}"
			unless nodeDesc= app._routerCache.get cachePathKey
				nodeDesc= _resolveRouterPath app, ctx.method, path
				app._routerCache.set cachePathKey, nodeDesc

			# Route found
			if nodeDesc.status is 200
				node= nodeDesc.node
				ctx.route= node.route
				# Resolve params: [paramName, paramValue, ...]
				paramValues= nodeDesc.params
				appParams= app._params
				if paramValues.length
					len= paramValues.length
					i=0
					params= ctx.params
					while i<len
						paramName= paramValues[i++]
						paramValue= FastDecode paramValues[i++]
						if paramName is '*'
							params[paramName]= paramValue
						else
							params[paramName]= if (resolverFx= appParams[paramName][1]) then await resolverFx(paramValue, ctx, PATH_PARAM) else paramValue
				# Resolve query params
				params= ctx.query
				for paramName,paramValue of params
					if paramRes= appParams[paramName]
						if _isArray paramValue
							for v,i in paramValue
								paramValue[i]= await paramRes[1](v, ctx, QUERY_PARAM)
						else
							params[paramName]= await paramRes[1](paramValue, ctx, QUERY_PARAM)
				# Execute wrappers and the controller
				wrappers= nodeDesc.wrappers
				if wrappers.length
					nextWrapperIndex= 0
					execNextWrapper= =>
						if wrapper= wrappers[nextWrapperIndex++]
							return wrapper ctx, execNextWrapper
						else
							return nodeDesc.handler ctx
					cntrlResponse= await execNextWrapper()
				else
					cntrlResponse= await nodeDesc.handler ctx
			# 404 or 500
			else
				throw nodeDesc.status
		catch err
			# execute user defined handlers
			if (errorHandlers= nodeDesc?.errorHandlers) and errorHandlers.length
				for handler in errorHandlers
					try
						cntrlResponse= await handler ctx, err
						err= null
						break
					catch e
						err= e
			throw err if err

		# send retourned value
		unless ctx.finished
			if cntrlResponse? and (cntrlResponse isnt ctx) or (cntrlResponse= ctx.result)
				if typeof cntrlResponse is 'string'
					await ctx.render cntrlResponse
				else
					await ctx.send ctx.result
		return
	# Main interface
	return (req, ctx)->
		settings= @settings
		try
			# Locals
			locals= ctx: ctx

			# prepare context
			ctx.app			= this
			ctx.settings	= settings
			# req.settings	= settings
			ctx.req			= req
			ctx.request		= req
			ctx.locals		= locals
			ctx.data		= locals
			# ctx.contentLength	=
			# ctx.contentType		=
			ctx.locale		= @defaultLocale
			ctx.encoding	= settings.defaultEncoding

			# Content type
			req.contentType= ContentTypeParse(ctp) if ctp= req.headers['content-type']
			# Parse Cookies
			ctx.cookies= req.cookies= if cookieHeader= req.headers.cookie then req.parseCookies(cookieHeader) else {}

			# PATH
			ctx.method= req.method
			ctx.url= url= req.url
			i= url.indexOf '?'
			if ~i
				pathname= url.substr(0,i)
				ctx.search= url.substr(i)
				ctx.query= URLQueryParser.parse url.substr(i+1)
			else
				pathname= url
				ctx.search= ''
				ctx.query= {}
			# Set to lowercase if case insensitive path
			pathname= pathname.toLowerCase() if settings.routerIgnoreCase
			ctx.pathname= pathname

			# Execute wrappers
			if (wrappers= @_wrappers) and wrappers.length
				nextWrapperIndex= 0
				execNextWrapper= =>
					if wrapper= wrappers[nextWrapperIndex++]
						return wrapper ctx, execNextWrapper
					else
						return _handleRequest this, ctx
				await execNextWrapper()
			else
				await _handleRequest this, ctx
		catch err
			try
				errHandleMap= settings.errors
				errCode= err
				if (typeof errCode is 'number') or (typeof errCode is 'string') or (errCode and (errCode= errCode.code))
					errHandler= errHandleMap[errCode] or errHandleMap.else
				else
					errHandler= errHandleMap.else
				cntrlResponse= await errHandler ctx, err
				unless ctx.finished
					if cntrlResponse? and (cntrlResponse isnt ctx) or (cntrlResponse= ctx.result)
						if typeof cntrlResponse is 'string'
							await ctx.render cntrlResponse
						else
							await ctx.send ctx.result
			catch e2
				ctx.fatalError 'REQUEST-HANDLER', e2
				ctx.status(500).send('Internal Error.') unless ctx.finished
		finally
			unless ctx.finished
				ctx.warn 'REQUEST-HANDLER', "Request leaved open: #{req.url}"
				await ctx.end()
		return
