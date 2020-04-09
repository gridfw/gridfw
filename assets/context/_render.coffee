###*
 * Render view
###
render: (path, data)->
	# Data
	data= if data then (_assign {}, @data, data) else @data
	# render&send
	@contentType= 'text/html'
	data= await @app.render @locale, path, data
	return @send data