source 'https://rubygems.org'

gem 'rack-domain',
  github: 'whatyouhide/rack-domain',
  require: 'rack/domain'

gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-cross_origin', require: 'sinatra/cross_origin'
gem 'sinatra-contrib', require: [
  'sinatra/json',
  'sinatra/namespace',
  'sinatra/config_file'
]

gem 'simpleidn'

gem 'redis', '~> 3.1'
gem 'bases', github: 'whatyouhide/bases'

gem 'whenever', '~> 0.9'

group :test do
  gem 'minitest', '~> 5', require: %w(minitest/autorun minitest/pride)
  gem 'minitest-reporters', '~> 1', require: 'minitest/reporters'
  gem 'rack-test', require: 'rack/test'
end

group :development do
  gem 'rake'
  gem 'pry'
  gem 'capistrano', '~> 3.2'
  gem 'capistrano-rvm', '~> 0.1'
  gem 'capistrano-bundler', '~> 1.1'
end
