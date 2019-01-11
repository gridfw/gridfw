###
Check options object for match
###
_checkOptionsEmptyArr = [] # Expected empty
_checkOptions= (fxName, args, requiredArgs, optionalArgs) ->
	options = args[0]
	requiredArgs = _checkOptionsEmptyArr unless requiredArgs
	optionalArgs = _checkOptionsEmptyArr unless optionalArgs
	# check arguments count
	if requiredArgs.length
		throw new Error "#{fxName}>> Expected Options as argument" unless args.length is 1
	else
		throw new Error "#{fxName}>> Expected no argument or Options" unless args.length in [0, 1]
	# check options is object
	if options
		throw new Error "#{fxName}>> Options expected object" unless typeof options is 'object'
	else if requiredArgs.length
		throw new Error "#{fxName}>> Required arguments: #{requiredArgs.join ', '}"
	# check for required arguments
	keys= Object.keys options
	reqA = []
	for k in requiredArgs
		reqA.push k unless k in keys
	throw new Error "#{fxName}>> Required options: #{reqA.join ', '}" if reqA.length
	# check for unknown options
	reqA.length = 0
	for k in keys
		reqA.push k unless k in requiredArgs or k in optionalArgs
	throw new Error "#{fxName}>> Unknown options: #{reqA.join ', '}" if reqA.length
	return