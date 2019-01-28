# App consts
exports.app = app =
	# modes
	DEV: 0
	PROD: 1
	# params
	PATH_PARAM : 0
	QUERY_PARAM: 1
	# default encoding
	DEFAULT_ENCODING: 'utf8'
### this file contains app default settings ###
exports.settings=
	####<========================== App Id =============================>####
	mode:
		value: 'dev'
		default: (app, value)-> ['dev', 'prod'].indexOf value
		check: (value)->
			throw new Error "Illegal mode #{mode}. Expected 'dev' or 'prod'" unless value in ['dev', 'prod']
	### name ###
	name:
		value: 'Gridfw-app'
		check: (value)->
			throw new Error 'Name expected string' unless typeof value is 'string'
	###* Author ###
	author:
		value: '-'
		check: (value)->
			throw new Error 'Author expected string' unless typeof value is 'string'
	###* Admin Email ###
	email: 
		value: '-'
		check: (value)->
			throw new Error 'Email expected string' unless typeof value is 'string'

	####<========================== LISTENING =======================>####
	port: 
		value: 0 # Random port
		check: (value)->
			throw new Error 'Listening port expected positive integer' unless Number.isSafeInteger(value) and value >= 0
	protocol:
		value: 'http'
		check: (value)->
			throw new Error 'protocol expected string' unless typeof value is 'string'
	path:
		value: '/'
		check: (value)->
			throw new Error 'path expected string' unless typeof value is 'string'
	####<========================== LOG =============================>####
	###*
	 * log level
	 * @default prod: 'info', dev: 'debug'
	###
	logLevel:
		value: 'debug'
		default: (app, mode)->
			if mode is 'dev' then 'debug' else 'info'
		check: (level)->
			accepted = ['debug', 'log', 'info', 'warn', 'error', 'fatalError']
			throw new Error "level expected in #{accepted.join ','}" unless level in accepted
			return

	####<========================== Upload =============================>####
	###*
	 * Upload limits
	###
	uploadLimits:
		value:
			size: 20 * (2**20) # Max body size (20M)
			fieldNameSize: 1000 # Max field name size (in bytes)
			fieldSize: 2**20 # Max field value size (default 1M)
			fields: 1000 # Max number of non-file fields
			fileSize: 10 * (2**20) # For multipart forms, the max file size (in bytes) (default 10M)
			files: 100 # For multipart forms, the max number of file fields
			parts: 1000 # For multipart forms, the max number of parts (fields + files) 
			headerPairs: 2000 # For multipart forms, the max number of header 
		check: (limits)->
			throw new Error "Expected Object" unless limits and typeof limits is 'object'
			reqFields = []
			for field in ['fieldNameSize', 'fieldSize', 'fields', 'fileSize', 'files', 'parts', 'headerPairs']
				if field of limits
					v = limits[field]
					throw new Error "#{field} expected positive integer" unless v is Infinity or Number.isInteger(v) and v > 0
				else
					reqFields.push field
			throw new Error "Required fields: #{reqFields.join ', '}" if reqFields.length
			return
	###*
	 * Upload default directory
	###
	# uploadDir:
	# 	default: (app, mode)-> require('os').tmpdir()
	# 	check: (dir)->
	# 		throw new Error "Dir path expected string" unless typeof dir is 'string'
	# 		return
	###*
	 * Upload timeout
	###
	# uploadTimeout:
	# 	value: 10 * 60 * 1000 # 10min
	# 	check: (tmout)->
	# 		throw new Error "Expected positive integer" unless tmout is Infinity or Number.isSafeInteger(tmout) and tmout > 0
	####<========================== Router =============================>####
	###*
	 * Route cache
	###
	routeCacheMax:
		value: 50
		check: (max)->
			throw new Error 'max expected positive number greater then 10' unless Number.isSafeInteger(max) and max >= 10
	###*
	 * Ignore trailing slashes
	 * 		off	: ignore
	 * 		0	: ignore, make redirect when someone asks for this URL
	 * 		on	: 'keep it'
	###
	trailingSlash:
		value: 0
		check: (value)->
			throw new Error 'trailingSlash expected in [0, false, true]' unless value in [0, off, on]
	###*
	 * when 1, ignore path case
	 * when on, ignore route static part case only (do not lowercase param values)
	 * when off, case sensitive
	 * @type {boolean}
	###
	routeIgnoreCase:
		value: on
		check: (value)->
			throw new Error 'routeIgnoreCase expected in [false, true, 1]' unless value in [1, on, off]

	####<========================== Request =============================>####
	###*
	 * Timeout
	 * 0 = infinity
	###
	# reqtimeout:
	# 	value: 20000
	# 	check: (tmout)-> throw new Error 'Expected number' unless Number.isSafeInteger(tmout) and tmout >= 0
	###*
	 * trust proxy
	###
	trustProxyFunction:
		#TODO
		value: (req, proxyLevel)-> on	
		check: (fx)->
			throw new Error 'trustProxyFunction expected function' unless typeof fx is 'function'
	####<========================== Render and output =============================>####
	###*
	 * Render pretty JSON, XML and HTML
	 * @default  false when prod mode
	###
	pretty:
		value: on # true if dev mode
		default: (app, mode)-> mode is 'dev'
		check: (value)->
			throw new Error 'pretty expected boolean' unless typeof fx is 'boolean'
	###*
	 * Etag function generator
	 * generate ETag for responses
	###
	etagFunction:
		#TODO
		value: (data)-> '' 
		check: (fx)->
			throw new Error 'etagFunction expected function' unless typeof fx is 'function'
	###*
	 * render templates
	 * we do use function, so the require inside will be executed
	 * inside the app and not the compiler
	###
	engines:
		value: {}
		default: (app, mode)->
			engines = Object.create null
			engines['.pug'] = require 'pug'
			return engines
		check: ->
			# TODO
	###*
	 * view Cache
	 * @when off: disable cache
	 * @when on: enable cache for ever
	 * @type {boolean}
	###
	viewCache:
		value: on
		default: (app, mode) ->
			mode isnt 'dev' # false if dev mode
		check: (value)->
			throw new Error 'viewCache expected boolean' unless typeof value is 'boolean'
	viewCacheMax:
		value: 50 # view cache max entries
		check: (value)->
			unless number.isSafeInteger(value) and value >= 10
				throw new Error 'viewCacheMax expected positive integer greater then 10'
	views: 
		value:[
			'views' # default folder
		]
		check: (value)->
			unless Array.isArray(value) and value.every (e)-> typeof e is 'string'
				throw new Error 'views should be a list of directory paths'
	####<========================== Errors =============================>####
	# Error templates
	errors:
		value:
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
			throw new Error 'Expected object' unless typeof value is 'object' and value
			throw new Error '"else" option is required and expected function' unless typeof value.else is 'function'
	####<========================== PLUGINS =============================>####
	# plugins
	devPlugins:
		value: {}
		check: (value)->
			throw new Error 'Expected map of plugins' unless typeof value is 'object' and value 
	plugins:
		value:
			'cookie':
				require: 'gridfw-cookie'
				# config
				secret: 'gw'
		# default: (app, mode)->
		# 	# dev or prod
		# 	isDev = mode is 0
		# 	# default logger
		# 	'gridfw-logger':
		# 		require: '../gridfw-logger'
		# 		level: if isDev then 'debug' : 'info'
		# 		target: 'console'
		check: (value)->
			throw new Error 'Expected map of plugins' unless typeof value is 'object' and value 

