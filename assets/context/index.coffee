'use strict'
http		= require 'http'
URL			= require('url').URL
# fastDecode	= require 'fast-decode-uri-component'
encodeurl	= require 'encodeurl'

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
	###
	redirect: (url)->
		@setHeader 'location', encodeurl url
		@statusCode = 302
		@end()
	###*
	 * Permanent redirect to this URL
	###
	redirectPermanent: (url)->
		@setHeader 'location', encodeurl url
		@statusCode = 301
		@end()
	###*
	 * Redirect back (go back to referer)
	###
	redirectBack: -> @redirect @req.getHeader('Referrer') || @baseURL

	### content type ###
	type: (type)->
		throw new Error 'type expected string' unless typeof type is 'string'
		@contentType = type
		this

	### ends request ###
	end: (data)->
		new Promise (resolve, reject)=>
			@_end data, (err)->
				if err then reject err
				else do resolve
	### response.write(chunk[, encoding], cb) ###
	write: (chunk, encoding)->
		new Promise (resolve, reject)=>
			@_write chunk, encoding || '<%= DEFAULT_ENCODING %>', (err)->
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
# _defineProperties 

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