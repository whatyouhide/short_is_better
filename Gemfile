source 'https://rubygems.org'

gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-contrib', require: %w(sinatra/json sinatra/namespace)
gem 'redis'
gem 'bases', '~> 1'

group :test do
  gem 'minitest', '~> 5', require: %w(minitest/autorun minitest/pride)
  gem 'minitest-reporters', '~> 1', require: 'minitest/reporters'
  gem 'rack-test', require: 'rack/test'
  gem 'fakeredis', github: 'guilleiguaran/fakeredis'
end

group :development do
  gem 'rake'
  gem 'pry', require: false
end
