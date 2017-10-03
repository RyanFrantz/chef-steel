# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef/steel/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-steel"
  spec.version       = Chef::Steel::VERSION
  spec.authors       = ["Ryan Frantz"]
  spec.email         = ["ryanleefrantz@gmail.com"]

  spec.summary       = %q{A tool to keep testing-related configurations up-to-date}
  spec.description   = <<-EOD
    Hone your tools with chef-steel!

    chef-steel is a tool that can keep testing-related configurations up-to-date
    within one or more repos.

    If you work within many different repos that share a common set of testing tools
    (i.e. Rubocop, Foodcritic, Travis, Jenkins, etc.) it can be easy for their
    configuration to drift. With chef-steel you can update one or more of these
    configuration files from a central repository, as needed.
  EOD
  spec.homepage      = 'https://github.com/RyanFrantz/chef-steel'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'choice', '~> 0.2', '>= 0.2.0'
  spec.add_runtime_dependency 'colorize', '~> 0.8', '>= 0.8.1'

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
