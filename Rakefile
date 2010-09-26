require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "straitjacket"
    gem.summary = %Q{PostgreSQL constraints in Ruby}
    gem.description = %Q{PostgreSQL constraints in Ruby}
    gem.email = "kyle@kylemaxwell.com"
    gem.homepage = "http://github.com/fizx/straitjacket"
    gem.authors = ["Kyle Maxwell"]
    gem.add_dependency "pg", ">= 0.8"
    gem.add_development_dependency "activerecord", ">= 2.3.8"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "straitjacket #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :spec do
  task :setup do
    require "rubygems"
    require "active_record"
    require "yaml"
    config = YAML.load(File.read("spec/database.yml"))
    ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
    ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
    ActiveRecord::Base.establish_connection(config)
    
  end
end
