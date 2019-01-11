###*
 * Error
 * -----------------
 * 404 : Page or file not found
 *
 * 500 : internal server error
 *
 *
 * EISDIR: Directory error
###
#=include ../commons/_index.coffee
class GError extends Error
	###*
	 * Error
	 * @param  {number|string} code - error code
	 * @param  {string} message - error message
	###
	constructor: (code, message, extra)->
		super message
		_defineProperties this,
			code: value: code
			extra: value: extra
	### convert to JSON ###
	toJSON: ->
		code: @code
		message: @message
		stack: @stack
		extra: @extra
	toString: ->
		err = "\nGError[#{@code}]: #{@stack}\n"
		extra = @extra
		if extra
			if extra instanceof GError
				extra = extra.toString()
			else if extra instanceof Error
				extra = extra.stack
			else if typeof extra is 'object'
				extra = JSON.pretty extra
			err = err.concat "Caused by:\n", extra
		err
module.exports = GError