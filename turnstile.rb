require 'digest/sha2'
require 'uuid'
require 'json'

class Generate
  @@uuid = UUID.new
  
  def self.salt
    [Array.new(6) { rand(256).chr }.join].pack('m').chomp
  end
  
  def self.hash password, salt
    Digest::SHA256.hexdigest password + salt
  end
  
  def self.uuid; @@uuid.generate end
end

class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

module Turnstile
  module Model
    class Turnstile
      attr_accessor :realms, :users, :roles, :store

      def initialize store
        @store = store

        @realms = Realms.new store
        @users = Users.new store
        @roles = Roles.new store
      end
    end

    class Realms
      def initialize store; @store = store end

      def all; @store.smembers("realms") end

      def find realm
        raise "Realm must be specified." if realm.blank?

        JSON.parse(@store.get("realm-#{realm}")) rescue nil
      end

      def create realm
        raise "Realm must be specified." if realm.blank?
        
        r = JSON.parse(@store.get("realm-#{realm}")) rescue nil
        
        raise "Realm already exists." unless r.blank?
        
        @store.sadd("realms", realm)
        @store.set("realm-#{realm}", { "roles" => [], "created_on" => Time.now }.to_json)
      end

      def destroy realm
        raise "Realm must be specified." if realm.blank?
        raise "Realm doesn't exist." if @store.get("realm-#{realm}").blank?

        @store.srem("realms", realm)
        @store.del("realm-#{realm}")
      end

      def roles realm
        raise "Realm must be specified." if realm.blank?
        
        r = JSON.parse(@store.get("realm-#{realm}")) rescue nil
        
        raise "Realm doesn't exist." if r.blank?
        
        r["roles"]
      end

      def add_role realm, role
        raise "Realm must be specified." if realm.blank?
        raise "Role must be specified." if role.blank?

        r = JSON.parse(@store.get("realm-#{realm}")) rescue nil

        raise "Realm doesn't exist." if r.blank?
        raise "Role doesnt exist." unless @store.sismember("roles", role)
        raise "Realm already has role." if r["roles"].include? role

        r["roles"] << role
        
        @store.set("realm-#{realm}", r.to_json)
      end

      def remove_role realm, role
        raise "Realm must be specified." if realm.blank?
        raise "Role must be specified." if role.blank?

        r = JSON.parse(@store.get("realm-#{realm}")) rescue nil

        raise "Realm doesn't exist." if r.blank?
        raise "Role doesn't exist." unless @store.smember("roles", role)
        raise "Realm already has role." if r["roles"].include? role

        r["roles"] = r["roles"].reject { |r| r == role }
        
        @store.set("realm-#{realm}", r.to_json)
      end

      def has_role? realm, role
        raise "Realm must be specified." if realm.blank?
        raise "Role must be specified." if role.blank?

        r = JSON.parse(@store.get("realm-#{realm}")) rescue nil

        raise "Realm doesn't exist." if r.blank?

        r["roles"].include? role
      end

      alias :exists? :find
    end

    class Users
      def initialize store; @store = store end
      def all; @store.smembers("users") end

      def find name
        raise "Name must not be blank." if name.blank?

        JSON.parse(@store.get("user-#{name}")) rescue nil
      end

      def create name
        raise "Name must not be blank." if name.blank?
        
        u = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User already exists." unless u.blank?

        user = { "name" => name, "realms" => {}, "created_on" => Time.now }
        
        @store.set("user-#{name}", user.to_json)
        @store.sadd("users", name)
        
        user
      end

      def destroy name
        raise "Name must not be blank." if name.blank?
        
        u = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if u.blank?

        @store.del("user-#{name}")
        @store.srem("users", name)
      end
      
      def attribute name, key, value = nil
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        
        value ||= user[key]
        
        user[key] = value
        
        @store.set("user-#{name}", user.to_json)
      end

      def realms name
        raise "Name must not be blank." if name.blank?

        user = JSON.parse(@store.get("user-#{name}")) rescue nil

        raise "User doesn't exist." if user.blank?

        user["realms"]
      end

      def add_realm realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User is already part of realm." unless user["realms"][realm].blank?
        
        salt = Generate.salt
        hash = Generate.hash password, salt
        
        user["realms"][realm] = { "roles" => [], "salt" => salt, "hash" => hash }
        
        @store.set("user-#{name}", user.to_json)
      end
      
      def remove_realm realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        
        user["realms"][realm] = nil
        
        @store.set("user-#{name}", user)
      end

      def in_realm? realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?

        user = JSON.parse(@store.get("user-#{name}")) rescue nil

        raise "User doesn't exist." if user.blank?

        user["realms"][realm]
      end

      def change_password realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        
        salt = Generate.salt
        hash = Generate.hash password, salt
        
        user["realms"][realm]["salt"] = salt
        user["realms"][realm]["hash"] = hash
        
        @store.set("user-#{name}", user)
      end
      
      def check_password realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        
        user["realms"][realm]["hash"] == Generate.hash(password, user["realms"][realm]["salt"])
      end

      def roles realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?

        user = JSON.parse(@store.get("user-#{name}")) rescue nil

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?

        user["realms"][realm]["roles"]
      end

      def authorized? realm, name, role
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Role must not be blank." if role.blank?

        user = JSON.parse(@store.get("user-#{name}")) rescue nil

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?

        user["realms"][realm]["roles"].include? role
      end
      
      def add_role realm, name, role
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Role must not be blank." if role.blank?

        user = JSON.parse(@store.get("user-#{name}")) rescue nil

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "Role already exists" if @store.sismember("roles", role)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        raise "User already has role." if user["realms"][realm]["roles"].include? role
        
        user["realms"][realm]["roles"] << role
        
        @store.set("user-#{name}", user.to_json)
      end
      
      def remove_role realm, name, role
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Role must not be blank." if role.blank?

        user = JSON.parse(@store.get("user-#{name}")) rescue nil

        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "Role doesn't exist" unless @store.sismember("roles", role)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        raise "User doesn't perform this role." unless user["realms"][realm]["roles"].include role
        
        user["realms"][realm]["roles"] = user["realms"][realm]["roles"].reject { |ro| ro == role }
        
        @store.set("user-#{name}", user.to_json)
      end

      def signin realm, name, password
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        raise "Password must not be blank." if password.blank?
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        raise "Password is incorrect." unless user["realms"][realm]["hash"] == Generate.hash(password, user["realms"][realm]["salt"])
        
        uuid = Generate.uuid
        
        @store.hset("uuids", uuid, { :name => name, :realm => realm }.to_json)
        
        user["realms"][realm]["uuid"] = uuid
        
        @store.set("user-#{user}", user.to_json)
        
        uuid
      end
      
      def signout realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm must not be blank." if realm.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        uuid = user["realms"][realm]["uuid"]
        
        raise "User doesn't exist." if user.blank?
        raise "User isn't part of realm." if user["realms"][realm].blank?
        raise "User isn't signed in." if uuid.blank?
        
        @store.hdel("uuids", uuid)
        
        user["realms"][realm]["uuid"] = nil
        
        @store.set("user-#{user}", user.to_json)
        
        nil
      end
      
      def signedin? realm, name
        raise "Name must not be blank." if name.blank?
        raise "Realm name must not be blank." if realm.blank?
        
        user = JSON.parse(@store.get("user-#{name}")) rescue nil
        
        raise "User doesn't exist." if user.blank?
        raise "Realm doesn't exist." unless @store.sismember("realms", realm)
        raise "User isn't part of realm." if user["realms"][realm].blank?
        
        user["realms"][realm]["uuid"]
      end
      
      def from_uuid uuid
        raise "uuid must not be blank." if uuid.blank?
        
        @store.hget("uuids", uuid)
      end

      alias :exists? :find
      alias :has_right? :authorized?
      alias :set_uuit :signin
      alias :uuid :signedin?
    end

    class Roles
      def initialize store; @store = store end
      def all; @store.smembers("roles") end

      def find role
        raise "Role name must not be blank." if role.blank?

        JSON.parse(@store.get("role-#{role}")) rescue nil
      end

      def create role, *rights
        raise "Role name must not be blank." if role.blank?

        r = JSON.parse(@store.get("role-#{role}")) rescue nil

        raise "Role already exists." unless r.blank?

        r = { :rights => rights, :created_on => Time.now }
        
        @store.set("role-#{role}", r.to_json)
        @store.sadd("roles", role)
      end

      def destroy role
        r = JSON.parse(@store.get("role-#{role}")) rescue nil
        
        raise "Role name must not be blank." if role.blank?
        raise "Role doesn't exist." if r.blank?

        @store.srem("roles", role)
        @store.del("role-#{role}")
      end

      def rights role
        r = JSON.parse(@store.get("role-#{role}")) rescue nil
        
        raise "Role name must not be blank." if role.blank?
        raise "Role doesn't exist." if r.blank?

        r["rights"]
      end

      def has_right? role, right
        r = JSON.parse(@store.get("role-#{role}")) rescue nil
        
        raise "Role name must not be blank." if role.blank?
        raise "Right must be specified." if right.blank?
        raise "Role doesn't exist." if r.blank?

        r["rights"].include? right
      end

      def add_right role, right
        raise "Role name must not be blank." if role.blank?
        raise "Right must be specified." if right.blank?
        
        r = JSON.parse(@store.get("role-#{role}")) rescue nil
        
        raise "Role doesn't exist." if r.blank?
        raise "Right already exists." if r["rights"].include? right

        r["rights"] << right
        
        @store.set("role-#{role}", r.to_json)
      end

      def remove_right role, right
        raise "Role name must not be blank." if role.blank?
        raise "Right must be specified." if right.blank?
        
        r = JSON.parse(@store.get("role-#{role}")) rescue nil
        
        raise "Role doesn't exist." if r.blank?
        raise "Right doesn't exist." unless r["rights"].include? right

        r["rights"] = r["rights"].reject { |ri| right == ri }
        
        @store.set("role-#{role}", r.to_json)
      end

      alias :exists? :find
    end
  end
end