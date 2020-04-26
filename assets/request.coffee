'use strict'
http = require 'http'
LOG_IGNORE= ->

###*
 * HTTP request
###
module.exports= class Request extends http.IncomingMessage
	constructor: (socket)->
		super socket
		@settings= null # current app settings
		return

	```
	get cookies(){
		var cookieHeader, secret, cookies;
		if(cookieHeader = this.headers.cookie){
			secret= this.settings.cookieSecret;
			cookies= cookie.parse(cookieHeader,{decode: (data)=>{
				try{
					data= decodeURIComponent(data)
					// decode cookie
					if(secret && data.startsWith('s'))
						data = AESCrypto.decrypt(data.substr(1), secret).toString(CryptoJS.enc.Utf8);
					// parse json value
					if(data.startsWith('j'))
						data= JSON.parse(data.substr(1));
					else
						data= data.substr(1);
				}catch(err){
					this.warn('cookie-parser', err)
				}
				return data;
				}});
		}
		else cookies= []
		Object.defineProperty(this, 'cookies', {value:cookies});
		return cookies;
	}
	```
	# LOGS
	debug:	LOG_IGNORE
	warn:	LOG_IGNORE
	info:	LOG_IGNORE
	error:	LOG_IGNORE
	fatalError: LOG_IGNORE 