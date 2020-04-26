###*
 * Default options
###
_assertString= (value)->
	throw 'Expected string' unless typeof value is 'string'
	return value
_assertBoolean=(value)->
	throw 'Expected boolean' unless typeof value is 'boolean'
	return value
_assertFunction=(value)->
	throw 'Expected function' unless typeof value is 'function'
	return value
_assertUInt= (value)->
	throw 'Expected positive int' unless Number.isSafeInteger(value) and value>=0
	return value
_assertUIntOrInfinity= (value)->
	throw 'Expected positive int or Infinity' unless (Number.isSafeInteger(value) and value>=0) or (value is Infinity)
	return value

OPTIONS_CHECK=
	isProd: _assertBoolean
	name:	_assertString
	author:	_assertString
	email:	_assertString
	cookieSecret:	_assertString

	###***********
	 * Views
	###
	views:	(path)-> Path.resolve path
	viewCacheMax: _assertUIntOrInfinity
	viewCacheTTL: _assertUIntOrInfinity
	viewCacheMaxBytes: _assertUIntOrInfinity

	###***********
	 * HTTP
	###
	protocol:	(value)->
		throw 'Expected http, https or http2' unless value in ['http', 'https', 'http2']
		return value
	host:		_assertString
	port:		_assertUInt
	path:	(value)->
		throw 'Expected string' unless typeof value is 'string'
		url = (new URL value, 'http://localhost/').pathname
		throw "Illegal PATH. did you mean [#{url}] instead of: [#{value}] ?" unless url is value
		return url
	# ip:			'0.0.0.0'
	# ipType:		'ipv4'

	###***********
	 * LOG MANAGEMENT
	###
	logLevel: (value)->
		levels = ['debug', 'log', 'info', 'warn', 'error', 'fatalError']
		throw "Expected: #{levels.join ','}" unless value in levels
		return value

	###***********
	 * PROXY
	###
	###* Trust proxy level ###
	trustProxy: _assertFunction


	###***********
	 * ROUTER
	###
	###* trailing slashes ###
	trailingSlash: _assertBoolean

	###* routerIgnoreCase ###
	routerIgnoreCase:	_assertBoolean
	routerCacheMax:		_assertUIntOrInfinity
	routerCacheTTL:	_assertUIntOrInfinity

	###***********
	 * ERROR MANAGEMENT
	###
	errors: (value)->
		throw 'Expected object' unless typeof value is 'object' and value
		throw '"Options.else" expected function' unless typeof value.else is 'function'
		return value

	###***********
	 * Downloader
	###
	defaultEncoding: _assertString
	etag: (data)->		# add etag http header
		if data is false
			data= ->
		else if data is true
			data= ETag
		else unless typeof data is 'function'
			throw 'Illegal Etag'
		return data
	pretty: _assertBoolean	# show html, json and xml in pretty format
	jsonp: _assertFunction # jsonp callback name

	###***********
	 * APLOADER
	###
	upload_timeout: _assertUIntOrInfinity # Upload timeout
	upload_dir: _assertString # where to store uploaded files, default to os.tmp
	upload_parse: _assertBoolean # Do parse JSON and XML. save as file otherwise
	upload_limits: (data)->
		throw 'Expected object' unless typeof data is 'object' and data
		return _assign {}, @settings.upload_limits, data

	defaultLocale: (locale)->
		throw 'Expected string' unless typeof locale is 'string'
		locale= locale.toLowerCase()
		return locale
	i18nMapper: _assertString
	i18nCacheMax: _assertUIntOrInfinity
	i18nCacheTTL: _assertUIntOrInfinity
	i18nCacheMaxBytes: _assertUIntOrInfinity

	###***********
	 * SESSION
	###
	sessionCookie: _assertString