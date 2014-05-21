Gem::Specification.new do |s|
  s.name = "easy_menu"
  s.summary = "Simple menu bar dsl for Rails views"
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Gemfile", "README"]
  s.version = "0.3.0"
  s.authors = ['Nicholas Jakobsen', 'Ryan Wallace']

  s.add_dependency "rails", ">= 3.1"
end
