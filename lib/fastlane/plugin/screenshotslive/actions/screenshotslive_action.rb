require "zip"
require "fileutils"
require_relative "../helper/api_client"

module Fastlane
  module Actions
    class ScreenshotsliveAction < Action
      def self.run(params)
        api_key = params[:api_key]
        yaml_path = params[:yaml_config]
        output_dir = params[:output_directory]
        base_url = params[:base_url]

        yaml_config = File.read(yaml_path)
        UI.message("Dispatching render via Screenshots.live API...")

        client = Screenshotslive::ApiClient.new(api_key: api_key, base_url: base_url)

        result = client.render(yaml_config: yaml_config)
        job_id = result.dig("data", "id") || result["id"]
        UI.message("Render job dispatched: #{job_id}")

        UI.message("Waiting for render to complete...")
        job = client.poll_job(job_id: job_id)

        download_url = job.dig("data", "downloadUrl") || job["downloadUrl"]
        unless download_url
          raise "Render completed but no download URL returned"
        end

        UI.message("Downloading rendered screenshots...")
        zip_data = client.download(url: download_url)

        FileUtils.mkdir_p(output_dir)
        zip_path = File.join(output_dir, "screenshots.zip")
        File.binwrite(zip_path, zip_data)

        UI.message("Extracting to #{output_dir}...")
        Zip::File.open(zip_path) do |zip_file|
          zip_file.each do |entry|
            dest = File.join(output_dir, entry.name)
            FileUtils.mkdir_p(File.dirname(dest))
            entry.extract(dest) { true }
          end
        end

        File.delete(zip_path)

        UI.success("Screenshots rendered and extracted to #{output_dir}")
        output_dir
      end

      def self.description
        "Generate app store screenshots via the Screenshots.live REST API"
      end

      def self.authors
        ["Eric Isensee"]
      end

      def self.return_value
        "Path to the output directory containing rendered screenshots in Fastlane-compatible folder structure"
      end

      def self.details
        "Sends a YAML configuration to the Screenshots.live render API, polls for completion, " \
        "downloads the rendered ZIP, and extracts it into a Fastlane-compatible folder structure " \
        "(iPhone 6.5, iPad 12.9, phoneScreenshots, tenInchScreenshots). " \
        "Use this as a drop-in replacement for frameit with full template customization."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :api_key,
            env_name: "SCREENSHOTSLIVE_API_KEY",
            description: "Your Screenshots.live API key",
            sensitive: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :yaml_config,
            description: "Path to the YAML configuration file for the render",
            type: String,
            verify_block: proc do |value|
              UI.user_error!("YAML config file not found: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_directory,
            description: "Directory to extract rendered screenshots into",
            default_value: "./screenshots",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :base_url,
            env_name: "SCREENSHOTSLIVE_BASE_URL",
            description: "Override the API base URL (for testing)",
            optional: true,
            type: String
          ),
        ]
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end

      def self.category
        :screenshots
      end

      def self.example_code
        [
          'screenshotslive(
            api_key: ENV["SCREENSHOTSLIVE_API_KEY"],
            yaml_config: "./screenshots.yml",
            output_directory: "./fastlane/screenshots"
          )',
        ]
      end
    end
  end
end
