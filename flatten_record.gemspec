$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "flatten_record/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "flatten_record"
  s.version     = FlattenRecord::VERSION
  s.authors     = ["Alvin S.J. Ng"]
  s.email       = ["email.to.alvin@gmail.com"]
  s.homepage    = "https://github.com/alvinsj/flatten_record"
  s.summary     = "An ActiveRecord plugin that denormalizes your existing ActiveRecord models"
  s.description = "An ActiveRecord plugin that denormalizes your existing ActiveRecord models. It includes generation of migration, observe updates on target model and changes the records accordingly. It's mainly built for performing faster queries on reporting."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["sped/**/*"]

  s.add_development_dependency "bundler"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rails"
  
  s.license = 'MIT'
end
