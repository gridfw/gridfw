###*
 * i18n module
###
# locales: ['fr', 'fr-FR', 'en', ...] # list of all available locales
# defaultLocale

###* Default locale ###
getdefaultLocale: -> @settings.defaultLocale
setDefaultLocale: (locale)->
	throw new Error 'Illegal argument' unless arguments.length is 1 and typeof locale is 'string'
	locale= locale.toLowerCase()
	throw new Error "Missing locale: #{locale}. Available are: #{@locales.join ', '}" unless locale in @locales
	@settings.defaultLocale= @defaultLocale= locale
	this # chain

###*
 * GET a locale translations
 * @param  {String} locale - locale to load
 * @return {Promise<Object>}      - loaded locales
 * @throws {Promise.reject 404} If locale missing
###
getLocale: (locale)->
	# load locale
	fileName= @_i18nPaths[locale.toLowerCase()]
	throw new GError 404, "Missing locale: #{locale}", null unless fileName
	return @_i18nCache.get fileName # Load JS file from cache or file
	

