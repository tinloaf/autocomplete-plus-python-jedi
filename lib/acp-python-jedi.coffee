{CompositeDisposable} = require 'atom'
$ = require 'jquery'

spawn = require('child_process').spawn
JediProvider = require('./jedi-provider')

apd = require('atom-package-dependencies');
MessagePanelView = require('atom-message-panel').MessagePanelView
PlainMessageView = require('atom-message-panel').PlainMessageView

test_acp = apd.require('autocomplete-plus')
if not test_acp?
  # This is required since the window that the messages are being attached to is not
  # initialized when this module is being read...
  setTimeout(() =>
    messages = new MessagePanelView
      title: 'Autocomplete-Plus is missing!'
      position: 'top'

    messages.attach();
    messages.add(new PlainMessageView({
      message: 'Autocomplete-Plus-Python-Jedi requires the Autocomplete-Plus package to work, which is not installed. Please install Autocomplete-Plus.'
      className: 'text-error'
    }));
  , 2000)

module.exports =
  config:
    completeArguments:
      type: 'boolean'
      default: true
      title: "Complete Arguments for Functions"
      description: "This will cause the suggestions for functions to include their arguments."
    directoryConfigFile:
      type: 'string'
      default: '.acp-python-jedi.cson'
      title: 'Per-directory Autocomplete-Plus-Python-Jedi Config File'
      description: "File containing information about the virtualenv to use for a given directory."

  provider: null

  activate: (state) ->

  deactivate: ->
    @provider = null

  provide: ->
    unless @provider?
      @provider = new JediProvider()
    @provider
