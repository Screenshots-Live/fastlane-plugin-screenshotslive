require "faraday"
require "faraday/multipart"
require "json"

module Fastlane
  module Screenshotslive
    class ApiClient
      BASE_URL = "https://api.screenshots.live"
      RENDER_PATH = "/render/api"
      RENDER_WITH_PICTURES_PATH = "/render/render-with-pictures"
      POLL_PATH_PREFIX = "/render/get-render/"
      POLL_INTERVAL = 3
      MAX_POLL_ATTEMPTS = 200

      def initialize(api_key:, base_url: nil)
        @api_key = api_key
        @base_url = base_url || BASE_URL
        @conn = Faraday.new(url: @base_url) do |f|
          f.adapter Faraday.default_adapter
        end
      end

      def render(yaml_config:)
        response = @conn.post(RENDER_PATH) do |req|
          req.headers["Authorization"] = "Bearer #{@api_key}"
          req.headers["Content-Type"] = "text/yaml"
          req.body = yaml_config
        end

        unless response.success?
          body = JSON.parse(response.body) rescue {}
          raise "Screenshots.live API error (#{response.status}): #{body["message"] || response.body}"
        end

        JSON.parse(response.body)
      end

      def render_with_pictures(yaml_config:, picture_files:)
        multipart_conn = Faraday.new(url: @base_url) do |f|
          f.request :multipart
          f.adapter Faraday.default_adapter
        end

        payload = { "yaml" => yaml_config }
        picture_files.each do |filename, path|
          mime = "image/png"
          mime = "image/jpeg" if path.end_with?(".jpg", ".jpeg")
          payload[filename] = Faraday::Multipart::FilePart.new(path, mime, filename)
        end

        response = multipart_conn.post(RENDER_WITH_PICTURES_PATH) do |req|
          req.headers["Authorization"] = "Bearer #{@api_key}"
          req.body = payload
        end

        unless response.success?
          body = JSON.parse(response.body) rescue {}
          raise "Screenshots.live API error (#{response.status}): #{body["message"] || response.body}"
        end

        JSON.parse(response.body)
      end

      def poll_job(job_id:)
        attempts = 0
        loop do
          attempts += 1
          if attempts > MAX_POLL_ATTEMPTS
            raise "Render job #{job_id} timed out after #{MAX_POLL_ATTEMPTS * POLL_INTERVAL}s"
          end

          response = @conn.get("#{POLL_PATH_PREFIX}#{job_id}") do |req|
            req.headers["Authorization"] = "Bearer #{@api_key}"
          end

          unless response.success?
            raise "Failed to check job status (#{response.status})"
          end

          job = JSON.parse(response.body)
          status = job.dig("data", "status") || job["status"]

          case status
          when "Completed"
            return job
          when "Failed"
            error = job.dig("data", "error") || "Unknown error"
            raise "Render job failed: #{error}"
          end

          sleep(POLL_INTERVAL)
        end
      end

      def download(url:)
        response = Faraday.get(url)
        unless response.success?
          raise "Failed to download render output (#{response.status})"
        end
        response.body
      end
    end
  end
end
