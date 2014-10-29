lib = File.expand_path('../app', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bundler/setup'
Bundler.require(:default)

require 'base'
require 'shortener'
require 'ip_control'
require 'api'
require 'main_server'
