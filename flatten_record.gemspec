$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "flatten_record/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "flatten_record"
  s.version     = FlattenRecord::VERSION
  s.authors     = ["Alvin S.J. Ng"]
  s.email       = "email.to.alvin@gmail.com"
  s.homepage    = "https://github.com/alvinsj/flatten_record"
  s.summary     = "An ActiveRecord plugin that denormalizes your existing ActiveRecord models"
  s.description = "It provides an easier way to create denormalized records to be used for reporting, includes generation of migration file."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]
  
  s.add_dependency 'rails', ">= 3.2.12", "< 5"

  s.add_development_dependency "rspec-rails", "~> 2.14"
  s.add_development_dependency "sqlite3", "~> 1.3"

  s.license = 'MIT'
end
