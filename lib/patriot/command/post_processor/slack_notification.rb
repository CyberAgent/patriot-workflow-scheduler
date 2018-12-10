require 'rest_client'
require 'json'

# usage:
# slack_notification api_key: slack_api_key, channel: slack_channel, username: username(any), on: 'failed'
# slack_notification api_key: slack_api_key, channel: slack_channel, username: username(any), on: ['succeeded', 'failed']
module Patriot
  module Command
    module PostProcessor
      class SlackNotification < Patriot::Command::PostProcessor::Base
        API_KEY     = :api_key
        CHANNEL     = :channel
        USERNAME    = :username
        ON_PROP_KEY = :on

        # retrial
        COUNT_PROP_KEY = :count

        declare_post_processor_name :slack_notification

        def validate_props(props)
          raise "#{API_KEY} is not specified" unless props.has_key?(API_KEY)
          raise "#{CHANNEL} is not specified" unless props.has_key?(CHANNEL)
          raise "#{USERNAME} is not specified" unless props.has_key?(USERNAME)
          raise "#{ON_PROP_KEY} is not specified" unless props.has_key?(ON_PROP_KEY)
        end

        def process(cmd, worker, job_ticket)
          if should_notice?(cmd, job_ticket)
            http_request(job_ticket, Patriot::Command::ExitCode.name_of(job_ticket.exit_code), url(worker))
          end
          return true
        end

        def url(worker)
          return worker.config.get("slack.notification.#{@props[API_KEY]}.url")
        end

        def should_notice?(cmd, job_ticket)
          on = @props[ON_PROP_KEY]
          on = [on] unless on.is_a?(Array)
          on = on.map{|o| Patriot::Command::ExitCode.value_of(o)}

          if on.include?(job_ticket.exit_code)
            if Patriot::Command::ExitCode.name_of(job_ticket.exit_code) == 'SUCCEEDED'
              return true
            else
              retrial = cmd.post_processors.select{|pp| pp.is_a?(Patriot::Command::PostProcessor::Retrial)}[0]
              if retrial == nil || retrial.props[COUNT_PROP_KEY] <= 1
                return true
              end
            end
          end

          return false
        end

        def http_request(job_ticket, state, url)
          icon_emoji = {}
          icon_emoji['SUCCEEDED'] = ':good:'
          icon_emoji['FAILED']    = ':no_good:'

          retries = 0
          begin
            return RestClient.post(
              url,
              {
                channel: @props[CHANNEL],
                username: @props[USERNAME],
                icon_emoji: icon_emoji[state],
                text: <<-EOT
job_id: #{job_ticket.job_id} #{state}!!!

---
exec_host: #{job_ticket.exec_host}
#{job_ticket.description}
EOT
              }.to_json,
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
            uri = URI.parse(url)
            if uri.scheme != 'http' && uri.scheme != 'https'
              return false
            end
          rescue URI::InvalidURIError
            return false
          end
          return true
        end
      end
    end
  end
end
