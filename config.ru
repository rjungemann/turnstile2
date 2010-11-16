# work in progress. May be unstable!

# TO-DO
#   show the two methods of using Turnstile--as a Sinatra middleware, or using
#     cascades.

require 'sinatra/base'
require 'moneta'
require 'moneta/memory'
require "#{File.dirname(__FILE__)}/lib/turnstile_app"

module Turnstile
  class App < Sinatra::Base
    register Sinatra::Turnstile
    
    set :realm, "sample_realm"
    set :signin_url, "/signin"
    set :after_signin_url, "/"
    set :email_config, "#{File.dirname(__FILE__)}/config/config.json"
    
    configure do
      turnstile_setup Moneta::Memory.new do |t|
        unless t.realms.find "sample_realm"
          t.roles.create "admin", "can_view_index_page", "can_view_admin_page"
          t.roles.create "guest", "can_view_index_page"
          
          t.realms.create "sample_realm"
          t.realms.add_role "sample_realm", "admin"
          t.realms.add_role "sample_realm", "guest"
          
          t.users.create "admin"
          t.users.add_realm "sample_realm", "admin", "test"
          t.users.add_role "sample_realm", "admin", "admin"
        end
      end
    end
    
    get "/" do
      auth! "can_view_index_page"
      
      erb :"turnstile/index"
    end
    
    get "/create" do
      erb :"turnstile/create_get"
    end
    
    post "/create" do
      create_user params[:name], params[:email]
      
      erb :"turnstile/create_post"
    end
    
    post "/validate" do
      validate_user params[:name], params[:uuid]
      
      erb :"turnstile/validated"
    end
    
    get "/signin" do
      erb :"turnstile/signin_get"
    end
    
    post "/signin" do
      if params[:name].blank? || params[:password].blank?
        erb :"turnstile/signin_get"
      else
        signin params[:name], params[:password]
        
        erb :"turnstile/signin_post"
      end
    end
    
    post "/signout" do
      turnstile do |t|
        t.users.signout options.realm, params[:name]
      end
      
      redirect "/signin"
    end
  end
end

run Turnstile::App.new