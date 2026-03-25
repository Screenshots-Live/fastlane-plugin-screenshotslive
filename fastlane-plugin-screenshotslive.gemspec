lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastlane/plugin/screenshotslive/version"

Gem::Specification.new do |spec|
  spec.name          = "fastlane-plugin-screenshotslive"
  spec.version       = Fastlane::Screenshotslive::VERSION
  spec.author        = "Eric Isensee"
  spec.email         = "contact@screenshots.live"

  spec.summary       = "Generate app store screenshots via the Screenshots.live API"
  spec.homepage      = "https://github.com/screenshots-live/fastlane-plugin-screenshotslive"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w[README.md LICENSE]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "faraday", "~> 2.14"
  spec.add_dependency "faraday-multipart", "~> 1.1"
  spec.add_dependency "rubyzip", ">= 2.0", "< 3.0"

  spec.add_development_dependency "fastlane", "~> 2.200", ">= 2.200.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
