require 'rake/gempackagetask'

spec = Gem::Specification.new do |s| 
  s.name = "turnstile2"
  s.version = "0.2.4"
  s.author = "Roger Jungemann"
  s.email = "roger@thefifthcircuit.com"
  s.homepage = "http://thefifthcircuit.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A moneta-based authentication system, with realms, users, and roles."
  s.description = s.summary
  s.files = FileList["{bin,lib,vendor}/**/*"].to_a
  s.require_path = "lib"
  #s.autorequire = "name"
  #s.test_files = FileList["turnstile_spec.rb"].to_a
  s.has_rdoc = false
  #s.extra_rdoc_files = ["LICENSE.txt, README.txt"]
  s.add_dependency("moneta")
  s.add_dependency("uuid")
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end