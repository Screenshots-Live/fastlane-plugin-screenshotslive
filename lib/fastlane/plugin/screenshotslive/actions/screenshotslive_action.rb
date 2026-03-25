require "yaml"
require "zip"
require "fileutils"
require_relative "../helper/api_client"

module Fastlane
  module Actions
    class ScreenshotsliveAction < Action
      PICTURE_REF_PREFIX = "picture://"

      def self.run(params)
        api_key = params[:api_key]
        yaml_path = params[:yaml_config]
        output_dir = params[:output_directory]
        base_url = params[:base_url]
        overrides = params[:overrides] || {}

        yaml_config = File.read(yaml_path)
        picture_files = {}

        unless overrides.empty?
          yaml_config, picture_files = apply_overrides(yaml_config, overrides)
        end

        UI.message("Dispatching render via Screenshots.live API...")
        client = Screenshotslive::ApiClient.new(api_key: api_key, base_url: base_url)

        if picture_files.empty?
          result = client.render(yaml_config: yaml_config)
        else
          UI.message("Uploading #{picture_files.size} local screenshot(s)...")
          result = client.render_with_pictures(yaml_config: yaml_config, picture_files: picture_files)
        end

        job_id = result.dig("data", "jobId") || result.dig("data", "id")
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
            next if entry.directory?
            filename = File.basename(entry.name)
            dest = File.join(output_dir, filename)
            entry.extract(dest) { true }
          end
        end

        File.delete(zip_path)

        file_count = Dir.glob(File.join(output_dir, "*.*")).length
        UI.success("#{file_count} screenshots rendered and saved to #{output_dir}")
        output_dir
      end

      def self.apply_overrides(yaml_string, overrides)
        data = YAML.safe_load(yaml_string)
        picture_files = {}

        items = data["items"] || []
        items.each do |item|
          item_id = item["itemId"]
          next unless overrides.key?(item_id)

          overrides[item_id].each do |field, value|
            if field.to_s == "screenshotUrl" && File.exist?(value.to_s)
              filename = File.basename(value.to_s)
              picture_files[filename] = value.to_s
              item["screenshotUrl"] = "#{PICTURE_REF_PREFIX}#{filename}"
            else
              item[field.to_s] = value
            end
          end
        end

        [data.to_yaml, picture_files]
      end

      def self.description
        "Generate app store screenshots via the Screenshots.live REST API"
      end

      def self.authors
        ["Eric Isensee"]
      end

      def self.return_value
        "Path to the output directory containing rendered screenshot files"
      end

      def self.details
        "Sends a YAML configuration to the Screenshots.live render API, polls for completion, " \
        "downloads the rendered ZIP, and extracts flat screenshot PNGs into the output directory. " \
        "Override any YAML field per itemId via the overrides hash. If a screenshotUrl points " \
        "to a local file, it is automatically uploaded via the render-with-pictures endpoint."
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
            description: "Directory to save rendered screenshot PNGs (flat, no subdirectories)",
            default_value: "./screenshots",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :overrides,
            description: "Hash of itemId => { field => value } to override in the YAML. " \
                         "If screenshotUrl points to a local file, it is uploaded automatically",
            optional: true,
            default_value: {},
            type: Hash
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
          '# Basic render
screenshotslive(
  api_key: ENV["SCREENSHOTSLIVE_API_KEY"],
  yaml_config: "./screenshots.yml",
  output_directory: "./fastlane/screenshots/en-US"
)',
          '# Override text and screenshots per item
screenshotslive(
  api_key: ENV["SCREENSHOTSLIVE_API_KEY"],
  yaml_config: "./screenshots.yml",
  output_directory: "./fastlane/screenshots/de-DE",
  overrides: {
    "text-item-id" => { "content" => "Neue Funktion", "color" => "#FF0000" },
    "device-frame-id" => { "screenshotUrl" => "./screens/de/home.png" },
  }
)',
        ]
      end
    end
  end
end
