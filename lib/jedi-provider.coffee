$ = require 'jquery'

spawn = require('child_process').spawn
readline = require('readline')
fs = require('fs')
path = require('path')

class JediProvider
	selector: '.source.python'

	inclusionPriority: 10
	excludeLowerPriority: true

	mapClass: (typeName) ->
		switch typeName
			when "function" then "function"
			when "module" then "import"
			when "class" then "class"
			when "instance" then "variable"
			when "statement" then "value"
			when "keyword" then "keyword"
			else ""

	handleProcessError: (identifier, err) ->
		console.log "Jedi Process " + identifier + " erroring out"
		@halted = true
		if identifier in @rls and @rls[identifier]?
			@rls[identifier].close()

	fileExists: (path) ->
		try
			stats = fs.lstatSync(path);
			return stats.isFile();
		catch e
			return false

	ascendModulesPath: (path) ->
		ascendedPath = path
		while (@fileExists(path + '/__init__.py'))
			oldPath = ascendedPath
			ascendedPath = path.dirname(ascendedPath)
			if (ascendedPath == oldPath)
				# Reached /
				return ascendedPath

		return ascendedPath

	collectPathsFor: (editor) ->
		projectPaths = atom.project.getPaths()
		ascendedModulePath = @ascendModulesPath(path.dirname(editor.getPath()))

		return (projectPaths.concat([ ascendedModulePath ])).sort()

	getPathsIdentifier: (editor) ->
		paths = @collectPathsFor(editor)
		return paths.join(':')

	sendPathToJedi: (proc, path) ->
		cmd =
			cmd: 'add_python_path'
			path: path
		cmdStr = JSON.stringify cmd
		cmdStr += '\n'

		proc.stdin.write cmdStr

	createJediFor: (editor, identifier) ->
		paths = @collectPathsFor(editor)

		proc = spawn("python", [ __dirname + '/jedi-cmd.py' ])

		proc.on('error', (err) => @handleProcessError(identifier, err))
		proc.on('exit', (code, signal) => @handleProcessError(identifier, code))

		rl = readline.createInterface({
			input: proc.stdout
		})
		rl.on('line', (dataStr) => @processData(dataStr))
		rl.on('close', => @handleProcessError(identifier))

		proc.stderr.on('data', (data) =>
  		console.log('Jedi.py ' + identifier + ' Error: ' + data);
		)

		@procs[identifier] = proc
		@rls[identifier] = rl

		@sendPathToJedi(proc, path) for path in paths

		console.log "Created Jedi for identifier " + identifier
		return proc

	getJediFor: (editor) ->
		identifier = @getPathsIdentifier(editor)
		if identifier in @procs
			return @procs[identifier]

		return @createJediFor(editor, identifier)


	constructor: ->
		@procs = {}
		@rls = {}

		@reqCount = 0
		@cbs = {}

	showSimpleError: (message, title) ->
		atom.confirm
			message: title
			detailedMessage: message
			buttons: ['OK']

	processMsg: (data) ->
		switch data['msg']
			when "jedi-missing" then @showSimpleError("We could not find the jedi package in your python environment. Please make sure that you activated any virtual environment that you wanted to work in. Also make sure that you installed jedi. You can do so via a simple 'pip install jedi' command.", "Jedi not found")
			else ""

	processData: (dataStr) ->
		data = JSON.parse(dataStr)
		if not data['reqId'] in @cbs
			throw new Error

		reqId = data['reqId']

		if reqId == "msg"
			@processMsg(data)
			return

		prefix = data['prefix']
		[resolve, reject] = @cbs[reqId]

		suggestions = []
		for suggestionData in data['suggestions']
			wholeText = prefix + suggestionData['complete']

			# TODO watch this
			if atom.config.get('autocomplete-plus-python-jedi.completeArguments') and suggestionData['params']? and suggestionData['params'].length > 0
				useSnippet = true
				snippet = wholeText + "("

				i = 1
				for param in suggestionData['params']
					if i != 1
						snippet += ", "

					description = if param["description"].length > 0 then param["description"] else "arg"

					if param['description'].split('=').length == 1
						snippet += "${" + i + ":" + description + '}'
					else
						arg_name = $.trim(param['description'].split('=')[0])
						arg = $.trim(param['description'].split('=')[1])
						snippet += arg_name + " = ${" + i + ":" + arg + '}'

					i += 1

				snippet += ")"
			else
				useSnippet = false

			suggestion = {
				rightLabel: suggestionData['description'],
				description: suggestionData['docstring'],
				type: @mapClass suggestionData['type']
			}

			if useSnippet
				suggestion.snippet = snippet
			else
				suggestion.text = wholeText

			suggestions.push(suggestion)

		delete @cbs[reqId]

		resolve(suggestions)

	isInString: (scopeDescriptor) ->
		scopeArray = scopeDescriptor.getScopesArray()
		(return true if scope.indexOf('string.') == 0) for scope in scopeArray
		(return true if scope.indexOf('comment.') == 0) for scope in scopeArray
		return false

	getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
		proc = @getJediFor(editor)

		if @isInString(scopeDescriptor)
			return new Promise (resolve, reject) =>
				resolve([])

		reqId = @reqCount++
		payload =
			reqId: reqId
			prefix: prefix
			source: editor.getText()
			line: bufferPosition.row
			column: bufferPosition.column

		prom = new Promise (resolve, reject) =>
			@cbs[reqId] = [resolve, reject]

		argStr = JSON.stringify payload
		argStr += "\n"
		proc.stdin.write(argStr)
		return prom

module.exports = JediProvider
