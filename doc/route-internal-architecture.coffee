
###
@example
* /path/to/resource
* /users/:user/books/:book
* /users/:user/*
*
* /:/:/:
###

routes =
	# first level contains HTTP methods
	get: {ROUTE}
		# this level contains routes
		name: '/' # main route
		# this contains known nodes
		nodes: {ROUTE}
	head: "..."
	post: "..."
	delete: "..."



{ROUTE} =
	n: 'param name' # name: in case of param
	c: function(ctx){} # check function, in case of param

	loglevel: 'warn' # log level

	# sub nodes
	n:
		name2: [{ROUTE}]
		name3: [{ROUTE}]
	# parmas: known nodes will match first, after that we will go throw params
	p: [
		{ROUTE}
	]

	# middlewars: list of middlewares tobe used
	m: []
