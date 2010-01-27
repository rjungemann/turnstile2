begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "jeweler"
    s.executables = "jeweler"
    s.summary = "Simple and opinionated helper for creating Rubygem projects on GitHub"
    s.email = "josh@technicalpickles.com"
    s.homepage = "http://github.com/technicalpickles/jeweler"
    s.description = "Simple and opinionated helper for creating Rubygem projects on GitHub"
    s.authors = ["Josh Nichols"]
    s.files =  FileList["[A-Z]*", "{bin,generators,lib,test}/**/*", 'lib/jeweler/templates/.gitignore']
    s.add_dependency 'schacon-git'
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end