###*
 * i18n module
###

###*
 * Set context locale
 * @return {Promise}
 * @throws {ERROR} If locale not found
###
setLocale: (locale)->
	# Load locale
	map= await @app.getLocale locale
	@i18n= map
	@locale= locale
	return map

###*
 * Load locale from users request
###
loadLocale: ->
	app= @app
	locale= @acceptsLanguages(app.locales) or app.defaultLocale
	map= await app.getLocale locale
	@i18n= map
	@locale= locale
	return map
