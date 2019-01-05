'use strict'
http		= require 'http'
fastDecode	= require 'fast-decode-uri-component'
Buffer		= require('safe-buffer').Buffer
encodeurl	= require 'encodeurl'
sendFile	= require 'send'
onFinishLib	= require 'on-finished'
contentDisposition = require 'content-disposition'
mimeType	= require 'mime-types'

REQUEST_PROTO = require './request'

{gettersOnce} = require '../lib/define-getter-once'
GError			= require '../lib/error'


#=include ../commons/_index.coffee

# create empty attribute for performance
UNDEFINED_=
	value: undefined
	configurable: true
	writable: true

### response ###
CONTEXT_PROTO=
	###*
	 * redirect to this URL
	 * @param {string} url - target URL
	 * @param {boolean} isPermanent - If this is a permanent or temp redirect
	 * (use this.redirectPermanent(url) in case of permanent redirect)
	###
	redirect: (url, isPermanent)->
		# set location header
		@setHeader 'location', encodeurl url
		#TODO add some response (depending on "accept" header: text, html, json, ...)
		# status code
		@statusCode = if isPermanent then 302 else 301
		# end request
		@end()
	###*
	 * Permanent redirect to this URL
	###
	permanentRedirect: (url)-> @redirect url, true
	###*
	 * Redirect back (go back to referer)
	###
	redirectBack: -> @redirect @req.getHeader('Referrer') || '/'

	###*
	 * Render page
	 * @param  {[type]} path [description]
	 * @return {[type]}      [description]
	###
	render: (path, locals)->
		if locals
			Object.setPrototypeOf locals, @locals
		else
			locals = _create @locals
		@app._render path, locals
		.then (html)=>
			# @contentType = 'text/html'
			@send html

	### content type ###
	type: (type)->
		throw new Error 'type expected string' unless typeof type is 'string'
		@contentType = type
		this
		# switch arguments.length
		# 	when 1
		# 		@_type = type
		# 		this
		# 	when 0
		# 		@_type
		# switch arguments.length
		# 	when 1, 2
		# 		if type is 'bin'
		# 			@setHeader 'content-type', 'application/octet-stream'
		# 		else
		# 			@setHeader 'content-type', (CONTENT_TYPE_MAP[type] || type).concat '; charset=', encoding || DEFAULT_ENCODING
		# 		this
		# 	when 0
		# 		@getHeader 'content-type'
		# 	when 2
		# 		@setHeader 'content-type', type
		# 		this
		# 	else
		# 		throw new Error 'Illegal arguments'
	

	### ends request ###
	end: (data)->
		new Promise (resolve, reject)=>
			@_end data, (err)->
				if err then reject err
				else do resolve
	### response.write(chunk[, encoding], cb) ###
	write: (chunk, encoding)->
		new Promise (resolve, reject)=>
			@_write chunk, encoding || '<%= app.DEFAULT_ENCODING %>', (err)->
				if err then reject err
				else resolve()
	### Append http header ###
	addHeader: (name, value)->
		prev= @getHeader name
		unless prev
			prev = []
		else unless Array.isArray prev
			prev = [prev]
		prev.push value
		@setHeader name, prev
		# chain
		this

	### commons with Context ###
	accepts				: REQUEST_PROTO.accepts
	acceptsEncodings	: REQUEST_PROTO.acceptsEncodings
	acceptsCharsets		: REQUEST_PROTO.acceptsCharsets
	acceptsLanguages	: REQUEST_PROTO.acceptsLanguages

# promisify native functions
# Object.defineProperties 

#=include _send-response.coffee
#=include _context-content-types.coffee

gettersOnce CONTEXT_PROTO,
	### if the request is aborted ###
	aborted: -> @req.aborted
	###*
	 * Key-value pairs of request header names and values. Header names are lower-cased.
	###
	reqHeaders: -> @req.headers
	###*
	 * HTTP version of th request
	###
	httpVersion: -> @req.httpVersion
	###*
	 * Used method
	###
	method: -> @req.method

	### protocol ###
	protocol: -> @req.protocol

	### is https or http2 ###
	secure: -> @req.secure
	ip: -> @req.ip
	hostname: -> @req.hostname
	fresh: -> @req.fresh
	### if request made using xhr ###
	xhr: -> @req.xhr

	### accept ###
	_accepts: -> @req._accepts

# exports
module.exports = CONTEXT_PROTO