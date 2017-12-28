require 'mail'
module Patriot
  module Command
    module PostProcessor
      class MailNotification  < Patriot::Command::PostProcessor::Base

        TO_PROP_KEY = :to
        ON_PROP_KEY = :on

        declare_post_processor_name :mail_notification

        def validate_props(props)
          raise "#{TO_PROP_KEY} is not specified" unless props.has_key?(TO_PROP_KEY)
          raise "#{ON_PROP_KEY} is not specified" unless props.has_key?(ON_PROP_KEY)
        end

        def process(cmd, worker, job_ticket)
          on = @props[ON_PROP_KEY]
          on = [on] unless on.is_a?(Array)
          on = on.map{|o| Patriot::Command::ExitCode.value_of(o)}
          exit_code = job_ticket.exit_code
          return unless on.include?(exit_code)
          case exit_code
          when Patriot::Command::ExitCode::SUCCEEDED then process_success(cmd, worker, job_ticket)
          when Patriot::Command::ExitCode::FAILED    then process_failure(cmd, worker, job_ticket)
          end
          return true
        end

        def process_success(cmd, worker, job_ticket)
          from = worker.config.get(Patriot::Util::Config::ADMIN_USER_KEY)
          to   = @props[TO_PROP_KEY]
          subject = "#{job_ticket.job_id} has been successfully finished"
          body = "#{job_ticket.job_id} has been successfully finished \n\n --- \n #{job_ticket.description}"
          deliver(from, to, subject, body)
        end

        def process_failure(cmd, worker, job_ticket)
          from = worker.config.get(Patriot::Util::Config::ADMIN_USER_KEY)
          to   = @props[TO_PROP_KEY]
          subject = "#{job_ticket.job_id} has been failed"
          body = "#{job_ticket.job_id} has been failed \n\n --- \n #{job_ticket.description}"
          to = [to] unless to.is_a? Array
          to.each{|to_addr| deliver(from, to_addr, subject, body) }
        end

        def deliver(from_addr, to_addr, msg_subj, msg_body)
          Mail.deliver do
            from from_addr
            to   to_addr
            subject msg_subj
            body    msg_body
          end
        end

      end
    end
  end
end


