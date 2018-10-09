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
		default: (value)-> ['dev', 'prod'].indexOf value
		check: (value)->
			throw new Error "Illegal mode #{mode}. Expected 'dev' or 'prod'" unless value in ['dev', 'prod']
	### name ###
	name:
		value: 'GridFW'
		check: (value)->
			throw new Error 'Name expected string' unless typeof value is 'string'
	###* Author ###
	author:
		value: 'GridFW@coredigix'
		check: (value)->
			throw new Error 'Author expected string' unless typeof value is 'string'
	###* Admin Email ###
	email: 
		value: 'contact@coredigix.com'
		check: (value)->
			throw new Error 'Email expected string' unless typeof value is 'string'

	####<========================== LOG =============================>####
	###*
	 * log level
	 * @default prod: 'info', dev: 'debug'
	###
	logLevel:
		value: 'debug'
		default: (app, mode)->
			if mode is 0 then 'debug' else 'info'
		check: (level)->
			accepted = ['debug', 'log', 'info', 'warn', 'error', 'fatalError']
			throw new Error "level expected in #{accepted.join ','}" unless level in accepted

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
		default: (app, mode)-> mode is 0
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
		value: (app, mode)->
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
			mode isnt 0 # false if dev mode
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
	errorTemplates:
		value: null
		default: (app, mode)->
			# dev mode
			if mode is 0
				'404': path.join __dirname, '../../build/views/errors/d404'
				'500': path.join __dirname, '../../build/views/errors/d500'
			# prod mode
			else
				'404': path.join __dirname, '../../build/views/errors/404'
				'500': path.join __dirname, '../../build/views/errors/500'
		check: (value)->
			unless typeof value is 'object' and value
				throw new Error 'ErrorTemplates a map of "Error-code" to "template path"'
			for k,v in value
				unless /^d[0-9]{3}/.test k
					throw new Error "Error templates: Illegal error code: #{k}"
				unless typeof v is 'string'
					throw new Error "Error templates: errorTemplates.#{k} mast be file path"
			return
	# plugins
	plugins:
		value: {}
		# default: (app, mode)->
		# 	# dev or prod
		# 	isDev = mode is 0
		# 	# default logger
		# 	'gridfw-logger':
		# 		require: '../gridfw-logger'
		# 		level: if isDev then 'debug' : 'info'
		# 		target: 'console'
		check: (value)->
			throw new Error 'plugins option expected map of plugins' unless typeof value is 'object' and value 

