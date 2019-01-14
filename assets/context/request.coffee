'use strict'

http = require 'http'
ContentTypeParse = require('content-type').parse
parseRange = require 'range-parser'
proxyaddr  = require 'proxy-addr'
fresh		= require 'fresh'

{gettersOnce} = require '../lib/define-getter-once'

# upload lib
Busboy = require 'busboy'
RawBody= require 'raw-body'
Zlib = require 'zlib'
Iconv= require 'iconv-lite'
NativeFs = require 'fs'
fs		= require 'mz/fs'
Path	= require 'path'

#=include ../commons/_index.coffee
#=include _upload.coffee

### response ###
REQUEST_PROTO=
	###*
	 * Parse Range header field, capping to the given `size`.
	 *
	 * Unspecified ranges such as "0-" require knowledge of your resource length. In
	 * the case of a byte range this is of course the total number of bytes. If the
	 * Range header field is not given `undefined` is returned, `-1` when unsatisfiable,
	 * and `-2` when syntactically invalid.
	 *
	 * When ranges are returned, the array has a "type" property which is the type of
	 * range that is required (most commonly, "bytes"). Each array element is an object
	 * with a "start" and "end" property for the portion of the range.
	 *
	 * The "combine" option can be set to `true` and overlapping & adjacent ranges
	 * will be combined into a single range.
	 *
	 * NOTE: remember that ranges are inclusive, so for example "Range: users=0-3"
	 * should respond with 4 users when available, not 3.
	 *
	 * @param {number} size
	 * @param {object} [options]
	 * @param {boolean} [options.combine=false]
	 * @return {number|array}
	 * @public
	 ###
	range: (size, options) ->
		range = @getHeader 'Range'
		if range
			parseRange size, range, options
	###
	@deprecated use "getHeader" instead
	used only to keep compatibility with expressjs
	###
	header : (name)-> @getHeader name
	get: (name)-> @getHeader name

	### upload post data ###
	upload: _uploadPostData

module.exports = REQUEST_PROTO

gettersOnce REQUEST_PROTO,
	### accept ###
	_accepts: -> accepts this
	### protocol ###
	protocol: ->
		#Check for HTTP2
		protocol = if @connection.encrypted then 'https' else 'http'
		# if trust immediate proxy headers
		if @s[<%= settings.trustProxyFunction %>] this, 0
			h = @getHeader 'X-Forwarded-Proto'
			if h
				i = h.indexOf ','
				protocol = (if i >= 0 then h.substr 0, i else h).trim()
		protocol
	### if we are using https ###
	secure: -> @protocol in ['https', 'http2'] #TODO check for this
	### client IP ###
	ip: -> proxyaddr this, @s[<%= settings.trustProxyFunction %>]

	###*
	 * When "trust proxy" is set, trusted proxy addresses + client.
	 *
	 * For example if the value were "client, proxy1, proxy2"
	 * you would receive the array `["client", "proxy1", "proxy2"]`
	 * where "proxy2" is the furthest down-stream and "proxy1" and
	 * "proxy2" were trusted.
	 *
	 * @return {Array}
	 * @public
	###
	ips: ->
		addrs = proxyaddr this, @s[<%= settings.trustProxyFunction %>]
		addrs.reverse().pop()
		addrs
	###*
	 * Parse the "Host" header field to a hostname.
	 *
	 * When the "trust proxy" setting trusts the socket
	 * address, the "X-Forwarded-Host" header field will
	 * be trusted.
	 *
	 * @return {String}
	###
	hostname: ->
		trust = @s[<%= settings.trustProxyFunction %>]
		host = @getHeader('X-Forwarded-Host')
		if host and trust @connection.remoteAddress, 0
			host #TODO check for IPv6 lateral support
		else
			@getHeader 'host'
	###*
	 * Check if the request is fresh, aka
	 * Last-Modified and/or the ETag
	 * still match.
	 * @return {boolean}
	###
	fresh: ->
		method = @method
		res = @res
		status = res.statusCode

		# only for "get" and "head"
		if method in ['GET', 'HEAD'] and ( 200 <= status < 300 or status is 304 )
			fresh @headers,
				etag: res.getHeader 'ETag'
				'last-modified': res.getHeader 'Last-Modified'
			#TODO check for this it works
		else false
	###
	 * Check if the request is stale, aka
	 * "Last-Modified" and / or the "ETag" for the
	 * resource has changed.
	 * @return {boolean}
	###
	stale: -> !@fresh

	xhr: -> @getHeader('X-Requested-With')?.toLowerCase() is 'xmlhttprequest'

	###*
	 * data type
	 * @return {Object} - {type: string, parameters: {param: value}}
	###
	contentType: ->
		ctp = @headers['content-type']
		ctp and ContentTypeParse ctp


### commons with Context ###
props=
	### request: return first accepted type based on accept header ###
	accepts: value: ->
		acc = @_accepts
		acc.encodings.apply acc, arguments
	### Request: Check if the given `encoding`s are accepted.###
	acceptsEncodings: value: ->
		acc = @_accepts
		acc.types.apply acc, arguments
	### Check if the given `charset`s are acceptable ###
	acceptsCharsets: value: ->
		acc = @_accepts
		acc.charsets.apply acc, arguments
	### Check if the given `lang`s are acceptable, ###
	acceptsLanguages: value: ->
		acc = @_accepts
		acc.languages.apply acc, arguments
_defineProperties REQUEST_PROTO, props