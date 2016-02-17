module Patriot
  module Tool
    module PatriotCommands
      # handle jobs in JobStore
      module Job

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'job [delete|show_dependency] job_id [job_id ..]', 'manage job(s) in job store'
          def job(subcmd, *job_id)
            opts = symbolize_options(options)
            conf        = {:type => 'job'}
            conf[:path] = opts[:config] if opts.has_key?(:config)
            config      = load_config(conf)
            job_store   = Patriot::JobStore::Factory.create_jobstore(Patriot::JobStore::ROOT_STORE_ID, config)

            case subcmd
            when "delete"
              job_id.each do |jid|
                if job_store.delete_job(jid)
                  puts "#{jid} is deleted" 
                else
                  puts "#{jid} does not exist"
                end
              end
            when "show_dependency"
              job_id.each do |jid|
                dep = ""
                dep = [job_id] | build_producer_string_values(job_store, jid, 1)
                puts dep.join("\n")+"\n"
              end
            else
              puts "unknown sub command #{subcmd}"
              help('job')
            end
          end

          no_tasks do
            def build_producer_string_values(job_store, job_id, indent)
              values = []
              job = job_store.get(job_id)
              job[Patriot::Command::REQUISITES_ATTR].each do |product|
                products = job_store.get_producers(product)
                values << "#{'  '*indent}<= #{product} = WARN: no producer exists" if products.empty?
                products.each do |p|
                  jid = p['job_id']
                  state = p[Patriot::Command::STATE_ATTR]
                  dep_status = "#{jid}, #{state}"
                  producer_job = job_store.get(jid, :include_dependency => true)
                  unless producer_job['consumers'].map{|c| c['job_id']}.include?(job_id)
                    dep_status = "WARN: currupted dependency #{dep_status}"
                  end
                  values << "#{'  '*indent}<= #{product} = #{dep_status}"
                  values |= build_producer_string_values(job_store, jid, indent+1)
                end
              end
              return values
            end
          end

        end
      end
    end
  end
end
