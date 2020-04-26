###*
 * Set log level
###
_logLevels= ['debug', 'info', 'warn', 'error', 'fatalError', 'disabled']
_defineProperties GridFw.prototype,
	logLevel:
		get: -> @_logLevel
		set: (level)->
			# set
			levelIndex= _logLevels.indexOf level
			throw new Error "Supported log levels are: #{_logLevels.join(',')}. Unknown level: #{level}" unless ~levelIndex
			@_logLevel= level
			settings= @settings
			# APP
			@debug=		if levelIndex is 0 then settings.log_debug else LOG_IGNORE
			@info=		if levelIndex <= 1 then settings.log_info else LOG_IGNORE
			@warn=		if levelIndex <= 2 then settings.log_warn else LOG_IGNORE
			@error=		if levelIndex <= 3 then settings.log_error else LOG_IGNORE
			@fatalError=if levelIndex <= 4 then settings.log_fatalError else LOG_IGNORE
			# Context
			contextProto= Context.prototype
			requestProto= Request.prototype
			contextProto.debug=		requestProto.debug=			if levelIndex is 0 then settings.log_debug else LOG_IGNORE
			contextProto.info=		requestProto.info=			if levelIndex <= 1 then settings.log_info else LOG_IGNORE
			contextProto.warn=		requestProto.warn=			if levelIndex <= 2 then settings.log_warn else LOG_IGNORE
			contextProto.error=		requestProto.error=			if levelIndex <= 3 then settings.log_error else LOG_IGNORE
			contextProto.fatalError=requestProto.fatalError=	if levelIndex <= 4 then settings.log_fatalError else LOG_IGNORE
			return
