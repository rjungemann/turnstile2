require 'minitest/spec'
require 'minitest/autorun'
require 'redis'
require "#{File.dirname(__FILE__)}/../turnstile"

describe Turnstile::Model::Turnstile do
  describe "realms" do
    it "should allow a realm to be created" do
      @t = Turnstile::Model::Turnstile.new(Redis.new)

      flunk
    end
  end
end