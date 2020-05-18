###*
 * Cookies management
###
setCookie: (name, value, options)->
	throw new Error 'Cookie name expected string' unless typeof name is 'string'
	options?= {path:'/'}
	# stringify value
	if typeof value is 'string'
		value = ".#{value}"
	else if value?
		value = "j#{JSON.stringify value}"
	else
		value = '.'
	# signe cookie
	if secret= @settings.cookieSecret
		value = 's' + AESCrypto.encrypt value, secret
	# max age
	if 'maxAge' of options
		options.expires = new Date Date.now() + options.maxAge
	# path
	options.path ?= '/'
	# set as header
	@addHeader 'Set-Cookie', CookieLib.serialize name, value, options
	# chain
	this

clearCookie: (name, options)->
	if options
		options.expires= new Date(1)
	else
		options= expires: new date(1)
	return @setCookie name, '', options
clearCookies: ->
	options= expires: new date(1)
	cookies= @cookies
	for k of cookies
		@setCookie k, '', options
	this # chain