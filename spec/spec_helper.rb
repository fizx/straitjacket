$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'straitjacket'
require 'spec'
require 'spec/autorun'
require "rubygems"
require "active_record"
require "yaml"

Spec::Runner.configure do |config|
  cfg = YAML.load(File.read("#{File.dirname(__FILE__)}/database.yml"))
  ActiveRecord::Base.establish_connection(cfg)
  $conn = ActiveRecord::Base.connection.raw_connection
  
  class User < ActiveRecord::Base
    belongs_to :dog
  end
  
  class Dog < ActiveRecord::Base
    has_many :users
  end
end

def rebuild_sql
  $conn.exec <<-SQL
    DROP TABLE IF EXISTS users;
    DROP TABLE IF EXISTS dogs;
    CREATE TABLE users (
      id serial PRIMARY KEY,
      dog_id INT NOT NULL,
      name varchar(255)
    );
    
    CREATE TABLE dogs (
      id serial PRIMARY KEY,
      name varchar(255)
    );
  SQL
end