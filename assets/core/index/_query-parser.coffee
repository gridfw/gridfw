


_defineProperties GridFW.prototype,
	###*
	 * parse query
	 * enable user to define an other query parser,
	 * by simply overriding this one
	 * @param {string} rawQuery - query to parse
	 * @return {Object} Map of all params
	 * @example
	 * ctx.QueryParser({}, 'param=value&param2=value2')
	###
	queryParser: value: (rawQuery)->
		targetObj = _create null
		# [kye, value, ...]
		result = []
		if rawQuery
			for part in rawQuery.split '&'
				# parse
				idx = part.indexOf '='
				if idx isnt -1
					result.push (FastDecode part.substr 0, idx), (FastDecode part.substr idx + 1)
				else
					result.push (FastDecode part), ''
		# return
		result