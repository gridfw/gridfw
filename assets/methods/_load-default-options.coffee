###*
 * Load app default options
###
@_loadDefaultOptions: do ->
	# Default log function
	_default_log_serializer= (title, prettyFx)->
		(type, arg)->
			if typeof arg is 'object'
				if arg instanceof GError
					arg= arg.toString()
				else if arg instanceof Error
					arg= arg.stack
				# else
				# 	arg= PrettyFormat(arg,{maxDepth:3}).replace(/\n/g, "\n\t\t\t")
			# arg= new Error arg if typeof arg is 'string'
			console.log prettyFx(title, "\t", Chalk.inverse(type), arg)
			this # chain
	# Interface
	return (isProd)->
		isProd= !!isProd
		# return
		isProd: isProd # Default to dev mode
		name:	''
		author:	''
		email:	''

		###* HTTP ###
		protocol:	'http'
		host:		'localhost'
		port:		3000
		path:		'/'
		ipv6Only:	no
		###*
		 * Ignore trailing slashes and multiple slashes
		 * 		off	: ignore trailing slashes
		 * 		on	: 'keep it'
		###
		trailingSlash: no
		###*
		 * when true, ignore path case
		 * when false, case sensitive
		###
		routerIgnoreCase: yes
		routerCacheMax:		500 # Max route entries in the cache
		routerCacheTTL:		3600000 # 1h, time before removing route from the cache
		# ip:			'0.0.0.0'
		# ipType:		'ipv4'
		
		###* ERROR MANAGEMENT ###
		errors:
			404: (ctx, err)-> ctx.status(404).send 'Page not found.'
			'404-file': (ctx, err)-> ctx.status(404).send 'File not found.'
			'404-view': (ctx, err)->
				ctx.fatalError 'VIEW_ERROR', err
				ctx.status(500).send 'Missing view.'
			500: (ctx, err)->
				ctx.fatalError 'UNCAUGHT_ERROR', err
				ctx.status(500).send 'Internal Error.'
			else: (ctx, err)->
				ctx.fatalError 'UNCAUGHT_ERROR', err
				return ctx.status(500).send 'ERROR.'

		###* LOG MANAGEMENT ###
		logLevel: if isProd then 'warn' else 'debug'
		log_debug:	_default_log_serializer '[►] DEBUG'
		log_info:	_default_log_serializer '[i] INFO', Chalk.keyword('aqua')
		log_warn:	_default_log_serializer '[‼] WARN', Chalk.keyword('orange')
		log_error:	_default_log_serializer '[×] ERROR', Chalk.red
		log_fatalError:	_default_log_serializer '[×] FTL_ERR', Chalk.red.bold

		###* Trust proxy level ###
		trustProxy: (ctx, level)-> off # do not trust any proxy
		###* COOKIE ###
		cookieSecret: 'gw' # cookie crypt salt
		###* VIEWS ###
		views: 'views' # view render base directory
		viewCacheMax:		if isProd then 200 else 0 # Disable cache if is dev mode
		viewCacheTTL:		3600000 # 1h
		viewCacheMaxBytes:	50* (2**20) # 50M

		###* I18N ###
		defaultLocale:		'en'
		i18nMapper:			'i18n/mapper.json' # Path to JSON file that contains i18n file paths
		i18nCacheMax:		if isProd then 10 else 0 # Disable cache for dev mode
		i18nCacheTTL:		24*3600*1000 # 24h
		i18nCacheMaxBytes:	20*(2**20)	# 20M

		###* Downloader ###
		defaultEncoding: 'utf8'
		etag:	ETag		# add etag http header
		pretty:	not isProd	# show html, json and xml in pretty format
		jsonp: (ctx)-> ctx.query.cb or 'callback' # jsonp callback name

		###* APLOADER ###
		upload_timeout: 10 * 60 * 1000 # Upload timeout
		upload_dir: require('os').tmpdir() # where to store uploaded files, default to os.tmp
		upload_parse: yes # Do parse JSON and XML. save as file otherwise
		upload_limits:
			size: 20 * (2**20) # Max body size (20M)
			fieldNameSize: 1000 # Max field name size (in bytes)
			fieldSize: 2**20 # Max field value size (default 1M)
			fields: 1000 # Max number of non-file fields
			fileSize: 10 * (2**20) # For multipart forms, the max file size (in bytes) (default 10M)
			files: 100 # For multipart forms, the max number of file fields
			parts: 1000 # For multipart forms, the max number of parts (fields + files) 
			headerPairs: 2000 # For multipart forms, the max number of header