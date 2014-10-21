require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
end

task :find_the_failing_test do
  (ENV['TIMES'].to_i || 12).times do |i|
    print '.'

    out = `rake test`
    unless $?.success?
      puts out
      exit
    end
  end
end

task :console do
  require 'pry'
  require_relative 'main'
  binding.pry
end

task default: :test
