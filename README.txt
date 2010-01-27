turnstile
    by Roger Jungemann
    http://thefifthcircuit.com/

== DESCRIPTION:

Turnstile is meant to be a flexible authentication and authorization system for Ruby. Currently it is merely a set of "model" classes, although I will shortly release a set of Rack middleware and an HTTP client library which will allow one to create providers, consumers, and clients which are available to Rails apps (or any Rack-compatible app for that matter), for a modest "single sign-on" solution.

Turnstile is built on Moneta, which is a hot-swappable interface for various key-value stores. Moneta uses SDBM as its data-store by default, but it can also use Tokyo Cabinet, Redis, or even SQL-based sources, thanks to the DataMapper Moneta wrapper.

== FEATURES/PROBLEMS:

* I need to add in my set of Rack middleware for creating providers, consumers, and clients. I have a mostly completed set of code for these.
* I am considering OAuth and/or OpenID support for my provider, consumer, and client, which could be useful for different aspects of turnstile.

== SYNOPSIS:

To get started, try typing in `turnstile` in your terminal. This will open a prompt allowing one to interact with the turnstile database. Let's first try and create a role. A role is a collection of limited rights for a particular resource. For example, a web application with a "/treasures" url might want to limit access to that resource to only a small set of users. For example:

    Role.create "king", "/", "/treasures"
    Role.create "hero", "/"
    Role.create "damsel", "/"
    
Next, let's create a realm. A realm is a collection of resources which need to be authorized and authenticated. Let's create a realm called `magical_kingdom` and associate some roles with it.

    realm = "magical_kingdom"
    
    Realm.create realm, "king", "hero", "damsel"

Next, let's try actually creating a user.

    name, password = "mickey", "mouse"
    
    user = User.create "mickey"
    user.add_realm realm, password
    user.add_role realm, "hero"
    
Now, the important part. How does one sign in a user? How does one keep track of signedin users? Here's how to signin a user:    

    user.signin realm, password
    
Once a user is signed in, the `uuid` method will give a value which can be freely given to the user. The user can later be looked up by turnstile just by using the uuid for that user's session.

    uuid = user.uuid realm
    
    user = User.from_uuid uuid

You can also see if a user is signed into a realm, or sign them out.

    user.signedin? realm
    user.signout realm

== REQUIREMENTS:

* Moneta, uuid, and andand gems

== INSTALL:

    gem sources -a http://gems.github.com
    sudo gem install thefifthcircuit-turnstile
    
To use, either type `turnstile` into your terminal, or create a new text file, type in

    require 'rubygems'
    require 'turnstile'
    
    $t = Turnstile::Model::Turnstile.new # create and instantiate database
    Turnstile::Model::Turnstile.init # setup database with default values
    
    include Turnstile::Model
    
    User.create "minnie"