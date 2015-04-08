# autocomplete-plus-python-jedi package - A python Autocomplete Plus provider based on Jedi

This is a provider for the awesome [Autocomplete Plus](https://atom.io/packages/autocomplete-plus) making it ready for Python code.

## Features

* Autocompletion from Jedi_
* Suggestions include functions' methods (optionally) - just tab through them!
* Comes with bundled Jedi - no need for jedi in your pythonpath

## Installation

Either use Atoms package manager or `apm install autocomplete-plus-python-jedi`

## Changelog

This package was inspired by a very similar package by [fallenhitokiri](https://github.com/fallenhitokiri/autocomplete-plus-jedi).

2016-04-06 v. 0.2.4
* Add type indicators
* Some smaller fixes

2015-04-02	v. 0.2.1 - v.0.2.3
* Bugfix: Arguments with unknown names now called "arg"
* Improve behavior if ACP is not installed
* Prepare docstrings for when ACP implements this

2015-03-31 	v. 0.2.0
* Add function arguments to suggestions

2015-03-31 	v. 0.1.1
* Add bundled Jedi

2015-03-30 	v. 0.1.0
* Initial version. Autocompletion working.

.. _jedi : https://github.com/davidhalter/jedi/
