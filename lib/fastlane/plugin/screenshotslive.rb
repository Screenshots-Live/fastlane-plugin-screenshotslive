require "fastlane/plugin/screenshotslive/version"

module Fastlane
  module Screenshotslive
    def self.all_classes
      Dir[File.expand_path("**/{actions,helper}/*.rb", File.dirname(__FILE__))]
    end
  end
end

Fastlane::Screenshotslive.all_classes.each do |current|
  require current
end
