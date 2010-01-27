require File.join(File.dirname(__FILE__), 'turnstile')
Bundler.require_env :test

describe Turnstile::Model::Realms do
  it "should display a list of names of all realms" do
  
  end
  
  it "should search for a realm by name" do
  
  end
  
  it "should create a realm, given a name" do
  
  end
  
  it "should destroy a realm, given a name" do
  
  end
  
  it "should display a list of names of roles present on the realm" do
    
  end
  
  it "should allow for a role to be added from the realm" do
    
  end
  
  it "should allow for a role to be removed from the realm" do
    
  end
  
  it "should answer whether a role is present on a realm" do
    
  end
end

describe Turnstile::Model::Users do
  it "should display a list of names of all users" do
  
  end
  
  it "should search for a user by name" do
  
  end
  
  it "should create a user, given a name" do
  
  end
  
  it "should destroy a user, given a name" do
  
  end
  
  it "should display a list of names of realms the user is part of" do
    
  end
  
  it "should allow for a user to be added to a realm" do
    
  end
  
  it "should allow for a user to be removed from a realm" do
    
  end
  
  it "should be able to say whether a user is part of a realm" do
    
  end
  
  it "should allow for a user's password to be changed" do
    
  end
  
  it "should allow for a user's password to be checked" do
    
  end
end

describe Turnstile::Model::Roles do
  it "should display a list of names of all roles" do
  
  end
  
  it "should search for a role by name" do
  
  end
  
  it "should create a role, given a name" do
  
  end
  
  it "should destroy a role, given a name" do
  
  end
end