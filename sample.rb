require 'redis'
require "#{File.dirname(__FILE__)}/turnstile"

def turnstile
  redis = Redis.new
  redis.flushall

  Turnstile::Model::Turnstile.new(redis)
end

t = turnstile
t.realms.create("kingdom")
t.roles.create("royalty")
t.users.create("king")
t.users.add_realm("kingdom", "king", "king")
t.users.realms("king")
t.realms.add_role("kingdom", "royalty")
t.realms.roles("kingdom")
t.users.add_role("kingdom", "king", "royalty")
t.users.signin "kingdom", "king", "king"
t.users.authorized? "kingdom", "king", "royalty"
t.roles.find("royalty")
t.users.roles("kingdom", "king")
t.users.find("king")