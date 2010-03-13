# work in progress. May be unstable!

require 'net/smtp'
require 'erb'
require 'json'
require "#{File.dirname(__FILE__)}/turnstile"

module Sinatra
  module Turnstile
    module Helpers
      def turnstile; yield options.turnstile end
      
      def auth? right
        uuid = session[:uuid] || params[:uuid]
        
        return nil if(uuid.blank? and not options.signin_url.blank?)
        
        turnstile do |t|
          user = t.users.from_uuid uuid
          roles = t.users.roles options.realm, user["name"]
          valid_roles = roles.find_all { |r| t.roles.has_right? r, right }
          
          return nil if(valid_roles.blank?)
        end
        
        uuid
      end
      
      def auth! right
        query = ENV["QUERY_STRING"].blank? "" : "?#{ENV["QUERY_STRING"]}"
        
        session[:intended_action] = "#{ENV["SCRIPT_NAME"]}#{ENV["PATH_INFO"]}#{query}"
        
        redirect(options.signin_url) unless auth?(right)
      end
      
      def signin name, password
        if user_validated? name
          turnstile do |t|
            session[:uuid] = t.users.signin options.realm, name, password
          end
        end
        
        redirect_after_signin if session[:uuid]
      end
      
      def redirect_after_signin
        intended_action = session[:intended_action]
        session[:intended_action] = nil
        
        redirect(intended_action || options.after_signin_url || "/")
      end
      
      def create_user name, email
        user = t.users.create name
        uuid = Generate.uuid

        t.users.attribute name, "validation_uuid", uuid
        t.users.attribute name, "email", email

        send_validation_email email
      end
      
      def validate_user name, uuid
        turnstile do |t|
          if uuid == t.users.attribute(name, "validation_uuid")
            t.users.attribute params[:name], "validation_uuid", nil
            
            return true
          end
          nil
        end
      end
      
      def user_validated? name
        turnstile do |t|
          return true if(t.users.attribute(params[:name], "validation_uuid").nil?)
        end
        nil
      end
      
      def send_validation_email to, uuid
        unless options.email_config.blank?
          config = File.read(options.email_config)
          j = JSON.parse(config)
          template = File.read(j["template"])
          
          @j, @to, @uuid = j, to, uuid
          erb = ERB.new(template).result(binding)
          
          Net::SMTP.start(j["host"], j["port"], j['connection_host'], j['username'], j['password']) do |smtp|
            smtp.send_message erb, j["from"], to
          end
        end
      end
    end
    
    def self.registered(app)
      app.helpers ::Sinatra::Turnstile::Helpers
    end
    
    def turnstile_setup store
      turnstile = ::Turnstile::Model::Turnstile.new(store)
      
      set :sessions, true
      set :turnstile, turnstile
      
      yield turnstile
    end
  end
  
  register Sinatra::Turnstile
end