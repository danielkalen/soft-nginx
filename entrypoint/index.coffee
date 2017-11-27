global.Promise = require 'bluebird'
fs = require 'fs-jetpack'
execa = require 'execa'
nginx = require('which').sync 'nginx'
regex = require './regex'

Promise.resolve()
	.then ()-> fs.copyAsync './config/conf.d', '/etc/nginx/conf.d', overwrite:true
	.then ()-> console.log fs.read('/etc/nginx/conf.d/default.conf')
	# .then ()->
	# 	task = execa(nginx, ['-g','daemon off;'], {stdio:'inherit'})
	# 	require('p-event')(task, 'exit')


