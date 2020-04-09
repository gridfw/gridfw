'use strict'
###*
 * Error class
###
module.exports= class GError extends Error
	constructor: (code, message, causedBy)->
		super message
		@code= code
		@causedBy= causedBy
		return
	toString: ->
		causedBy= @causedBy
		causedBy= causedBy.stack if causedBy instanceof Error
		"""
		GError{
			message: #{@message}
			stack: #{@stack}
			causedBy: #{causedBy}
		}
		"""