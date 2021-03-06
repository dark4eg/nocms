require 'rubygems'
#require 'rake'
require 'bundler'

begin
  Bundler.setup
rescue Exception => e
  puts e
  system('bundle install')
  Bundler.setup
end 

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "nocms"
    gem.summary = %Q{A Ruby client for the NOCMS.org web service API.  Provides server-side helpers for Rails/Sinatra/Rack applications.}
    gem.description = %Q{A Ruby client for the NOCMS.org web service API.  Provides server-side helpers for Rails/Sinatra/Rack applications. keywords: ruby, rails, sinatra, rack, CMS, content management systems, search, cloud, SAAS, JSON, web service}
    gem.email = "nocms@powcloud.com"
    gem.homepage = "http://github.com/powcloud/nocms"
    gem.authors = ["Darren Rush"]
    gem.add_development_dependency "shoulda"
    gem.add_dependency "activesupport"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

task :cruise => [:geminstaller, :print_environment, :test]

task :geminstaller do
  system('bundle install') || raise('could not install some dependencies')
  #require 'geminstaller'
  #GemInstaller.run('--sudo --exceptions') || raise("GemInstaller failed")
end


task :print_environment do
  puts <<-ENVIRONMENT
Build environment:
     #{`uname -a`.chomp}
  #{`ruby -v`.chomp}
  SQLite3:    #{`sqlite3 -version`}
  #{`gem env`}
Local gems:
   #{`gem list`.gsub(/^/, '  ')}
  ENVIRONMENT
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "nocms #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
