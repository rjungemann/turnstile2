require 'minitest/spec'
require 'minitest/autorun'
require 'redis'
require "#{File.dirname(__FILE__)}/../turnstile"

def turnstile
  redis = Redis.new
  redis.flushall

  Turnstile::Model::Turnstile.new(redis)
end

describe Turnstile::Model::Turnstile do
  describe "realms" do
    it "should be creatable" do
      t = turnstile
      t.realms.create("kingdom")
      
      fail if t.realms.find("kingdom").blank?
      
      pass
    end
    
    it "should be destroyable" do
      t = turnstile
      t.realms.create("kingdom")
      
      fail if t.realms.find("kingdom").blank?
      
      t.realms.destroy("kingdom")
      
      fail unless t.realms.find("kingdom").blank?
      
      pass
    end
  end
  
  describe "users" do
    it "should be creatable" do
      t = turnstile
      t.users.create("king")
      
      fail if t.users.find("king").blank?
      
      pass
    end
    
    it "should be addable to a realm" do
      t = turnstile
      t.realms.create("kingdom")
      
      t.users.create("king")
      t.users.add_realm("kingdom", "king", "king")
      
      fail if t.users.in_realm?("kingdom", "king").blank?
      
      pass
    end
    
    it "should be able to change their passwords" do
      
    end
    
    it "should be destroyable" do
      
    end
  end
  
  describe "roles" do
    it "should be addable to a user" do
      
    end
    
    it "should be removable" do
      
    end
  end
end