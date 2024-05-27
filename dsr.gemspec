Gem::Specification.new do |spec|
  spec.name         = "dsr"
  spec.version      = "0.1.0"
  spec.summary      = "[WIP] Document Structure Recognizer -- currently a collection of common routines I use to build A.I.s"

  spec.author       = "Victor Maslov aka Nakilon"
  spec.email        = "nakilon@gmail.com"
  spec.license      = "MIT"
  spec.metadata     = {"source_code_uri" => "https://github.com/nakilon/dsr"}

  spec.add_dependency "nakischema"
  spec.add_dependency "hexapdf"
  spec.add_dependency "ferrum"

  spec.files        = %w{ LICENSE dsr.gemspec lib/dsr.rb }
end
