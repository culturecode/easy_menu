Gem::Specification.new do |s|
  s.name = "easy_menu"
  s.summary = "Simple menu bar DSL for Rails views"
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "README"]
  s.version = "0.4.14"
  s.authors = ['Nicholas Jakobsen', 'Ryan Wallace']

  s.add_dependency "rails", ">= 3.1"
end
