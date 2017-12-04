require 'rest_client'
require 'json'

module Patriot
  module Command
    module PostProcessor
      class HttpNotification < Patriot::Command::PostProcessor::Base

        CALLBACK_URL = :callback_url
        ON_PROP_KEY = :on

        declare_post_processor_name :http_notification

        def validate_props(props)
          raise "#{CALLBACK_URL} is not specified" unless props.has_key?(CALLBACK_URL)
          raise "#{CALLBACK_URL} is not a correct URL" unless valid_url?(props.fetch(CALLBACK_URL, ""))
          raise "#{ON_PROP_KEY} is not specified" unless props.has_key?(ON_PROP_KEY)
        end

        def process(cmd, worker, job_ticket)
          on = @props[ON_PROP_KEY]
          on = [on] unless on.is_a?(Array)
          on = on.map{|o| Patriot::Command::ExitCode.value_of(o)}
          exit_code = job_ticket.exit_code
          return unless on.include?(exit_code)

          callback_url = @props[CALLBACK_URL]
          case exit_code
          when Patriot::Command::ExitCode::SUCCEEDED then send_callback(job_ticket.job_id, callback_url, "SUCCEEDED")
          when Patriot::Command::ExitCode::FAILED then send_callback(job_ticket.job_id, callback_url, "FAILED")
          end
        end

        def send_callback(job_id, callback_url, state)
          retries = 0
          begin
            return RestClient.post(
              callback_url,
              {'job_id' => job_id, 'state' => state }.to_json,
              :content_type => 'application/json'
            )
          rescue RestClient::Exception => error
            retries += 1
            if retries < 3
              retry
            else
              raise error
            end
          end
        end

        def valid_url?(url)
          begin
             URI.parse(url)
          rescue URI::InvalidURIError
            return false
          end
          return true
        end

      end
    end
  end
end


