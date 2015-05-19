## 0.3.6
* Activate filterSuggestions

## 0.3.5
* Fix bug with ':' prefix causing lots of completions

## 0.3.4
* Fix message for atom with bundled ACP

## 0.3.3
* Jedi update

## 0.3.2
* Fix crash when used with Jedi 0.7
* More debbuging fixes

## 0.3.1
* Fix in case a traceback is generated

## 0.3.0
* Initial multi-pythonpath support: Editor tabs for which different PYTHONPATHs would be sane now use different Jedi instances
* The PYTHONPATH will now include the Atom project folder as well as some best guess to what the true project folder may be
* Better error handling

## 0.2.7
* Actually bundle Jedi
* Don't complete comments and strings

## 0.2.6
* Catch all exceptions thrown by Jedi

## 0.2.5
* Fix deprecations

## 0.2.4
* Add type indicators
* Some smaller fixes

## 0.2.1 - 0.2.3
* Bugfix: Arguments with unknown names now called "arg"
* Improve behavior if ACP is not installed
* Prepare docstrings for when ACP implements this

## 0.2.0
* Add function arguments to suggestions

## 0.1.1
* Add bundled Jedi

## 0.1.0 - First Release
* Initial version. Autocompletion working.
