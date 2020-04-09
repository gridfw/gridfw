###*
 * Redirects
###

###*
 * redirect to this URL
 * @param {string} url - target URL
###
goto: (url)->
	@setHeader 'location', EncodeUrl url
	@statusCode = 302
	@end()
###*
 * Permanent redirect to this URL
###
gotoPermanent: (url)->
	@setHeader 'location', EncodeUrl url
	@statusCode = 301
	@end()
###*
 * Redirect back (go back to referer)
###
goBack: ->
	baseUrl= @app.baseURL
	unless (url= @req.headers.referer) and url.startsWith(baseUrl) and not url.endsWith(@url)
		url= baseUrl
	@redirect url