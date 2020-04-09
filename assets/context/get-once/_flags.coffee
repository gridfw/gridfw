###*
 * FLAGS
###
aborted: -> @req.aborted

###*
 * HTTP version of th request
###
httpVersion: -> @req.httpVersion

### protocol ###
protocol: ->
	#Check for HTTP2
	req= @req
	protocol = if req.connection.encrypted then 'https' else 'http'
	# if trust immediate proxy headers
	if @settings.trustProxy this, 0
		h = req.getHeader 'X-Forwarded-Proto'
		if h
			i = h.indexOf ','
			protocol = (if i >= 0 then h.substr 0, i else h).trim()
	protocol

### if we are using https ###
secure: -> @protocol in ['https', 'http2']

### client IP ###
ip: -> proxyaddr @req, @settings.trustProxy

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
	addrs = proxyaddr @req, @settings.trustProxy
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
	req= @req
	host = req.getHeader('X-Forwarded-Host')
	if host and @settings.trustProxy req.connection.remoteAddress, 0
		host #TODO check for IPv6 lateral support
	else
		req.getHeader 'host'

###*
 * Check if the request is fresh, aka
 * Last-Modified and/or the ETag
 * still match.
 * @return {boolean}
###
fresh: ->
	status = @statusCode
	# only for "get" and "head"
	if @method in ['GET', 'HEAD'] and ( 200 <= status < 300 or status is 304 )
		fresh @req.headers,
			etag: @getHeader 'ETag'
			'last-modified': @getHeader 'Last-Modified'
		#TODO check for this it works
	else false
###
 * Check if the request is stale, aka
 * "Last-Modified" and / or the "ETag" for the
 * resource has changed.
 * @return {boolean}
###
stale: -> !@fresh

### if request made using xhr ###
xhr: -> @req.getHeader('X-Requested-With')?.toLowerCase() is 'xmlhttprequest'

###*
 * Requested data type
 * @return {Object} - {type: string, parameters: {param: value}}
###
reqType: ->
	ctp = @req.headers['content-type']
	ctp and ContentTypeParse ctp
