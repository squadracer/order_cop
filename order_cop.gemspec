# frozen_string_literal: true

require_relative "lib/order_cop/version"

Gem::Specification.new do |spec|
  spec.name = "order_cop"
  spec.version = OrderCop::VERSION
  spec.authors = ["Gauthier Monserand"]
  spec.email = ["gauthier@squadracer.com"]

  spec.summary = "Bullet-like gem to detect missing order clauses"
  spec.description = "Bullet-like gem to detect missing order clauses"
  spec.homepage = "https://github.com/squadracer/order_cop"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "rails", "~> 7.0"
  spec.add_dependency "binding_of_caller", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
