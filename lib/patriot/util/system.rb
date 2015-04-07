require 'fileutils'
require 'time'
module Patriot
  module Util
    module System
      class ExternalCommandException < Exception; end

      STDOUT_SUFFIX=".stdout"
      STDERR_SUFFIX=".stderr"

      PATRIOT_TMP_DIR_KEY        = "patriot.tmp.dir"
      DEFAULT_PATRIOT_TMP_DIR    = "/tmp/patriot-workflow-scheduler"
      MAX_ERROR_MSG_SIZE_KEY     = "patriot.max.error.size"
      DEFAULT_MAX_ERROR_MSG_SIZE = 256

      def tmp_dir(pid, dt, ts, tmp_dir = DEFAULT_PATRIOT_TMP_DIR)
        prefix = "p#{pid.to_s}"
        prefix = "j#{Thread.current[Patriot::Worker::JOB_ID_IN_EXECUTION]}" if Thread.current[Patriot::Worker::JOB_ID_IN_EXECUTION] 
        ts_exp = Time.at(ts).strftime("%Y%m%d_%H%M%S")
        return File.join(tmp_dir, dt, "#{prefix}_#{ts_exp}")
      end

      def do_fork(cmd, dt, ts, tmp_dir = DEFAULT_PATRIOT_TMP_DIR)
        cid = fork do 
          tmpdir = tmp_dir($$, dt, ts, tmp_dir)
          FileUtils.mkdir_p(tmpdir, {:mode => 0777})
          std_out = File.join(tmpdir, "#{$$.to_i}#{STDOUT_SUFFIX}")
          std_err = File.join(tmpdir, "#{$$.to_i}#{STDERR_SUFFIX}")
          STDOUT.reopen(std_out,"w")
          STDERR.reopen(std_err,"w")
          exec(cmd) 
        end
        return cid
      end

      def execute_command(command, &blk)
        so, se = nil

        time_obj = Time.now
        ts       = time_obj.to_i
        dt       = time_obj.strftime("%Y-%m-%d")

        tmp_dir_base  = @config.get(PATRIOT_TMP_DIR_KEY, DEFAULT_PATRIOT_TMP_DIR)

        # the forked variable is used for checking whether fork invocation hangs.
        #  (due to https://redmine.ruby-lang.org/issues/5240 ?)
        forked = false
        until forked
          cid = do_fork(command, dt, ts, tmp_dir_base)
          tmpdir = tmp_dir(cid, dt, ts, tmp_dir_base)
          i = 0
          # If fork hangs, output directory would not be created.
          # wait at most 5 seconds for the directory created.
          until forked || i > 5
            sleep(1)
            forked = File.exist?(tmpdir)
            i = i+1
          end
          # fork hanged, kill the hanged process.
          unless forked
            # check whether cid is id of child process to avoid to kill unrelated processes
            begin
              if Process.waitpid(cid, Process::WNOHANG).nil?
                @logger.warn("forked process :#{cid} hanged. kill #{cid}")
                Process.kill("KILL", cid)
                @logger.warn("SIGKILL sent to #{cid}")
                Process.waitpid(cid)
                @logger.warn("#{cid} is killed")
              else
                raise ExternalCommandException, "#{cid} is not a child of this"
              end
            rescue Exception => e
              @logger.warn "failed to kill hanged process #{cid}"
              raise e
            end
          end
        end

        @logger.info "executing #{command}: results stored in #{tmpdir}" 
        pid, status = Process.waitpid2(cid)
        so = File.join(tmpdir, "#{cid.to_i}#{STDOUT_SUFFIX}")
        se = File.join(tmpdir, "#{cid.to_i}#{STDERR_SUFFIX}")

        @logger.info "#{command} is finished" 
        return so if status.exitstatus == 0
        @logger.warn "#{command} end with exit status #{status.exitstatus}" 
        if block_given?
          yield(status, so, se)
        else
          max_err_size = @config.get(MAX_ERROR_MSG_SIZE_KEY, DEFAULT_MAX_ERROR_MSG_SIZE)
          err_size = File.stat(se).size
          err_msg =  "#{command}\n#{se} :"
          if err_size < max_err_size
            File.open(se){|f| err_msg = "#{err_msg}\n#{f.read}"}
          else
            err_msg = "#{err_msg} \n the size of stderr is #{err_size} (> #{max_err_size}" 
          end
          raise ExternalCommandException, err_msg
        end
      end

    end
  end
end

