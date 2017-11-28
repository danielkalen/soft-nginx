Promise = require 'bluebird'
fs = require 'fs-jetpack'
memoize = require 'fast-memoize'
indentString = require 'indent-string'
stringReplace = require 'string-replace-async'
IMPORT_REGEX = require('./regex').import

resolveImports = (content)->
	stringReplace content, IMPORT_REGEX, (e, whitespace, path)->
		path += '.conf' if not path.endsWith('.conf')
		path = require('path').resolve 'config',path

		Promise.resolve(path)
			.then loadFile
			.then (childContent)-> resolveImports childContent
			.then (result)-> indentString(result, 1, indent:whitespace)

loadFile = memoize (path)->
	fs.readAsync(path)
		.tap (content)-> if not content? then throw new Error "#{path} does not exist"

module.exports = resolveImports