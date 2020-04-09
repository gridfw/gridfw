###*
 * This is a DOC purpose file
###

###* POSSIBLE ROUTES ###
	"/"						# Root route
	"/path/to/resource"		# Static path
	"/:param1/to/:param2"	# Parametred path
	"/a/b/c/*"				# wildcard
	"/a/b/c/*param3"		# parametred wildcard
	# excapped static path: just add "?" before '*' or ':'
	"/a/b/?:c"				# escaped "/a/b/:c" static path
	"/a/b/?*"				# escaped "/a/b/*" static path
	"/a/b/?*cc"				# escaped "/a/b/*cc" static path

# Node format
::RouteNode
	# STATIC
	static:
		""				=> {::RouteNode} # when trailing slash is ignored
		"static-path"	=> {subRouteNode}

	# PARAMS
	"params"		=> [regex1, 'param1', {subRoute1}, regex2,  'param2',{subroute2}, ...]
	# ":param"		=> {subNode}
	# ":param2"		=> {subNode2}

	# WildCard
	"wildcards"		=> [wregex1, 'wparam1', {wsubRoute1}, wregex2, 'wparam2', {wsubroute2}, ...]
	"wildcard"		=> {subNode}

	# HTTP Methods
	"GET"			=> Handler
	"POST"			=> Handler
	"DELLETE"		=> Handler

	# Wrappers
	"wrappers"		=> [wrappers]

	# Error handlers
	"onError"		=> [handler1, handler2, ...]
