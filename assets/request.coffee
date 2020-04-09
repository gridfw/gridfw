'use strict'
http = require 'http'

###*
 * HTTP request
###
module.exports= class Request extends http.IncomingMessage
	constructor: (socket)->
		super socket
		return
