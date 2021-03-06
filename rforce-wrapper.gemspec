# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rforce-wrapper/version"

Gem::Specification.new do |s|
  s.name        = "rforce-wrapper"
  s.version     = RForce::Wrapper::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Brandon Tilley", "Daya Sharma"]
  s.email       = ["brandon@brandontilley.com, daya.sharma@gmail.com"]
  s.homepage    = "https://github.com/BinaryMuse/rforce-wrapper"
  s.summary     = "RForce-wrapper creates a wrapper around rforce to make it easier to use."
  s.description = s.summary

  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    s.add_runtime_dependency 'rforce'
    s.add_development_dependency 'rspec'
    s.add_development_dependency 'mocha'
  else
    s.add_dependency 'rforce'
    s.add_dependency 'rspec'
    s.add_dependency 'mocha'
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
