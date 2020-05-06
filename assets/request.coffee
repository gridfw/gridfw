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
		@cookies= null # parsed cookies
		@contentType= null
		return
	# LOGS
	debug:	LOG_IGNORE
	warn:	LOG_IGNORE
	info:	LOG_IGNORE
	error:	LOG_IGNORE
	fatalError: LOG_IGNORE
