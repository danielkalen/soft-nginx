exports.env_var = /\$(\w+)/g
exports.command = /\`(.+?)\`/g
exports.placeholder = /\{\{(.+?)\}\}/g
exports.import = ///
	(
		[\ \t\r=]* 			# prior whitespace
	)
	import
	\s
	(\S+?)
///gm