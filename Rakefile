#
# Setup
#

load 'lib/tasks/redis.rake'

$LOAD_PATH.unshift 'lib'
require 'resque/tasks'

def command?(command)
  system("type #{command} > /dev/null 2>&1")
end

require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'


#
# Tests
#

require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |test|
  test.verbose = false
  test.libs << "test"
  test.libs << "lib"
  #test.test_files = FileList['test/child_killing_test.rb']
  #test.test_files = FileList['test/job_hooks_test.rb']
  #test.test_files = FileList['test/job_plugins_test.rb']
  #test.test_files = FileList['test/resque_hook_test.rb']
  # LAST: test.test_files = FileList['test/worker_test.rb']

  # x test.test_files = FileList['test/resque_test.rb']
  # x test.test_files = FileList['test/resque_failure_redis_test.rb']
  # x test.test_files = FileList['test/resque_failure_multiple_test.rb']
  # x test.test_files = FileList['test/resque-web_test.rb']
  # x test.test_files = FileList['test/rake_test.rb']
  # x test.test_files = FileList['test/plugin_test.rb']
  # x test.test_files = FileList['test/logging_test.rb']
  # x test.test_files = FileList['test/failure_base_test.rb']
end

if command? :kicker
  desc "Launch Kicker (like autotest)"
  task :kicker do
    puts "Kicking... (ctrl+c to cancel)"
    exec "kicker -e rake test lib examples"
  end
end


#
# Install
#

task :install => [ 'redis:install', 'dtach:install' ]


#
# Documentation
#

begin
  require 'sdoc_helpers'
rescue LoadError
end
