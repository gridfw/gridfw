###*
 * App default settings
###
_settingsInit = <%= initSettings %>
	####<========================== App Id =============================>####
	mode:
		default: 'dev'
		check: (value)-> throw 'Expected "dev" or "prod"' unless value in ['dev', 'prod']
	name:
		default: 'Gridfw-app'
		check: (value)-> throw 'Expected string' unless typeof value is 'string'
	author:
		default: '-'
		check: (value)-> throw 'Expected string' unless typeof value is 'string'
	email:
		default: '-'
		check: (value)-> throw 'Expected string' unless typeof value is 'string'
	###*
	 * Enable/disable default plugins if not overrided
	###
	enableDefaultPlugins:
		default: on
		check: (value)-> throw 'Expected true or false' unless typeof value is 'boolean'

	####<========================== LOG =======================>####
	logLevel:
		default: 'debug'
		check: (value)->
			levels = ['debug', 'log', 'info', 'warn', 'error', 'fatalError']
			throw "Expected: #{levels.join ','}" unless value in levels
	####<========================== LISTENING =======================>####
	port:
		default: 0 # Random port
		check: (value)-> throw 'Expected positive integer' unless (Number.isSafeInteger value) and value >= 0
	protocol:
		default: 'http'
		check: (value)-> throw 'Expected "http", "https" or "http2"' unless value in ['http', 'https', 'http2']
	
	####<========================== PROXY =======================>####
	baseURL:
		default: null # will be "http://localhost:****/" if behind proxy. Set this with correct value in that case.
		check: (value)->
			return null unless value
			throw 'Expected string' unless typeof value is 'string'
			url = new URL value
			url = url.origin + url.pathname.match(/.+\//)[0]
			throw "Expected intead: #{url}" unless url is value
			return url
	###*
	 * Trust proxy level
	###
	trustProxy:
		default: (ctx, level)-> off # do not trust any proxy
		check: (value)-> throw 'Expected function' unless typeof value is 'function'


	####<========================== Router =======================>####
	# cacheSize:
	# 	default: 50 # max routes to be cached
	# 	check: (value)-> throw 'Expected number >= 10' unless Number.isSafeInteger(max) and max >= 10
	###*
	 * Ignore trailing slashes
	 * 		off	: ignore
	 * 		0	: ignore, make redirect when someone asks for this URL
	 * 		on	: 'keep it'
	###
	trailingSlash:
		default: 0
		check: (value)-> throw 'Expected true, false or 0' unless value in [true, false, 0]
	###*
	 * when 1, ignore path case
	 * when on, ignore route static part case only (do not lowercase param values)
	 * when off, case sensitive
	###
	routeIgnoreCase:
		default: on
		check: (value)-> throw 'Expected true, false or 1' unless value in [1, true, false]

	####<== JS CACHE: used for views, i18n or any service that loads JS files ==>####
	###*
	 * When
	 * 		- 0: Disable cache, always reload elements: useful for developpement, but decrease performance
	 * 		- Infinity: Every loaded elements will stay in memory. will increase performance, but check if you have enough memory
	 * 		- size >= 10k: Number or string representation of bytes: each element will stay in memory until not used anymore
	 * Idle timeout is handled by the framework dependant on current state.
	 * @default
	 * 		- 0 for dev mode
	 * 		- 20M for production
	###
	jsCacheMaxSize:
		default: 20 * 2**10 # 20M
		check: (value)->
			if typeof value is 'string'
				value = ByteParser.parse value
			else unless Number.isSafeInteger(value)
				throw 'Expected Number of String representation of bytes'
			throw 'Expected 0 or greater than 10k' unless value is 0 or value >= 10240
			return value
	jsCacheMaxSteps:
		default: 500
		check: (value)-> throw 'Expected number >= 10' unless Number.isSafeInteger(value) and value > 10
	####<========================== Errors =============================>####
	errors:
		default:
			# 404:(ctx, errCode, err)-> 'errors/404'
			# 500:(ctx, errCode, err)-> 'errors/500'
			else: (ctx, errCode, err)->
				# status code
				errCode = 500 unless Number.isSafeInteger errCode
				ctx.statusCode = errCode
				# debug
				if errCode >= 500
					ctx.fatalError 'UNCAUGHT_ERROR', err
				else
					ctx.debug 'UNCAUGHT_ERROR', err
				# content type
				ctx.contentType = 'text'
				# Message
				result = ["""
				URI: #{ctx.method} #{ctx.url}
				Code: #{errCode}
				"""]
				# render Error
				if typeof err is 'object'
					if err
						if typeof err.message is 'string'
							result.push "Message: #{err.message}"
						if typeof err.stack is 'string'
							result.push "Stack: #{err.stack}"
						if 'extra' of err
							result.push "Caused by: #{err.extra}"
				else if typeof err is 'string'
					result.push "Message: #{err}"
				# send
				return ctx.send result.join "\n"
		check: (value)->
			throw 'Expected object' unless typeof value is 'object' and value
			throw 'options.else is required' unless value.else
			throw 'options.else expected function' unless typeof value.else is 'function'