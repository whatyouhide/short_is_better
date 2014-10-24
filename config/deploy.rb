# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'short_is_better'

# Repository.
set :scm, :git
set :repo_url, 'git@github.com:whatyouhide/short_is_better'
set :branch, :master

# Server informations.
set :user, 'deploy'
server 'ze.lc', roles: %w(app), user: fetch(:user)

# Deployment.
set :deploy_via, :copy
set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}_#{fetch(:stage)}"
set :linked_files, %w(config/production.yml)
set :linked_dirs, %w(logs public tmp vendor/bundle)

# RVM.
set :rvm_type, :system
set :rvm_ruby_version, '2.1.3'

# Whenever.
set :whenever_roles, -> { :app }
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }


# Tasks.
namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart
  after :publishing, 'whenever:update_crontab'
end
