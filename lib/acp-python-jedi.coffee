{CompositeDisposable} = require 'atom'
{$} = require 'atom'

spawn = require('child_process').spawn
JediProvider = require('./jedi-provider')

apd = require('atom-package-dependencies');
apd.install();

module.exports =
  config:
    completeArguments:
      type: 'boolean'
      default: true
      title: "Complete Arguments for Functions"
      description: "This will cause the suggestions for functions to include their arguments."

  provider: null

  activate: (state) ->

  deactivate: ->
    @provider = null

  provide: ->
    unless @provider?
      @provider = new JediProvider()
    @provider
