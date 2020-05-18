###*
 * HTTP request
###
@Request= class Request extends http.IncomingMessage
	constructor: (socket)->
		super socket
		@settings= settings # current app settings
		@cookies= null
		@contentType= null
		return
	# LOGS
	debug:	LOG_IGNORE
	warn:	LOG_IGNORE
	info:	LOG_IGNORE
	error:	LOG_IGNORE
	fatalError: LOG_IGNORE
	# Parse cookies
	parseCookies: (cookieHeader)->
		secret= settings.cookieSecret
		return CookieLib.parse cookieHeader,
			decode: (data)->
				try
					data= decodeURIComponent data
					# decode cookie
					if secret and data.startsWith 's'
						data= AESCrypto.decrypt(data.substr(1), secret).toString(CryptoJS.enc.Utf8)
					# parse json value
					if data.startsWith 'j'
						data= JSON.parse data.substr 1
					else
						data= data.substr 1
				catch err
					ctx.warn 'cookie-parser', err
				return data
	### request: return first accepted type based on accept header ###
	accepts: (lst) -> @_accepts.types lst
	### Request: Check if the given `encoding`s are accepted.###
	acceptsEncodings: (lst)-> @_accepts.encodings lst
	### Check if the given `charset`s are acceptable ###
	acceptsCharsets: (lst)-> @_accepts.charsets lst
	### Check if the given `lang`s are acceptable, ###
	acceptsLanguages: (lgList)-> @_accepts.languages lgList
	```
	get _accepts(){
		var r= Accepts(this);
		_defineProperty(this, '_accepts', {configurable: true, enumerable: true, value: r, writable: true});
		return r;
	}
	```
