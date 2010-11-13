require 'minitest/spec'
require 'minitest/autorun'
require 'redis'
require "#{File.dirname(__FILE__)}/../turnstile"

describe Turnstile::Model::Turnstile do
  before do
    @t = Turnstile::Model::Turnstile.new(Redis.new)
  end
  
  describe "signin" do
    it "should allow a user to signin" do
      skip
    end
  end
end