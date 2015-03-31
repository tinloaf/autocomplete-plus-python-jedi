{$} = require 'atom'

spawn = require('child_process').spawn
readline = require('readline')

class JediProvider
	id: 'autocomplete-plus-python-jedi'
	selector: '.source.python'
	providerblacklist: null

	mapClass: (typeName) ->
		switch typeName
			when "function" then "entity name function"
			else ""

	handleProcessError: ->
		console.log "Jedi Process erroring out"
		@halted = true
		if @rl?
			@rl.close()

	constructor: ->
		@providerblacklist =
			'autocomplete-plus-fuzzyprovider': '.source.python'
			'autocomplete-plus-symbolprovider': '.source.python'
			'autocomplete-plus-jedi': '.source.python'

		projectPath = atom.project.getPath()
		command = "python"
		@proc = spawn(command, [ __dirname + '/jedi-cmd.py', projectPath ])

		@proc.on('error', (err) => @handleProcessError())
		@proc.on('exit', (code, signal) => @handleProcessError())

		@halted = false
		@isSetUp = false
		@reqCount = 0
		@cbs = {}

		@proc.stderr.on('data', (data) ->
  		console.log('Jedi.py Error: ' + data);
		)

	setUp: ->
		@rl = readline.createInterface({
			input: @proc.stdout
			})
		@rl.on('line', (dataStr) => @processData(dataStr))
		@rl.on('close', -> @handleProcessError)

		@isSetUp = true

	showSimpleError: (message, title) ->
		atom.confirm
			message: title
			detailedMessage: message
			buttons: ['OK']

	processMsg: (data) ->
		switch data['msg']
			when "jedi-missing" then @showSimpleError("We could not find the jedi package in your python environment. Please make sure that you activated any virtual environment that you wanted to work in. Also make sure that you installed jedi. You can do so via a simple 'pip install jedi' command.", "Jedi not found")
			else ""

		if data['halt']
			@halted = true

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

					if param['description'].split('=').length == 1
						snippet += "${" + i + ":" + param['description'] + '}'
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
			}

			if useSnippet
				suggestion.snippet = snippet
			else
				suggestion.text = wholeText

			suggestions.push(suggestion)

		delete @cbs[reqId]

		resolve(suggestions)

	getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
		if not @isSetUp
			@setUp()

		if @halted
			return new Promise (resolve, reject) =>
				reject()

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
		@proc.stdin.write(argStr)
		return prom

module.exports = JediProvider
