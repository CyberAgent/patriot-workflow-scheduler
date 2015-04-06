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

        # TODO refactor
        ## ts = 現在時刻（UNIXタイム）
        ## dt = 今日の年月日（yyyy-mm-dd形式）
        time_obj = Time.now
        ts       = time_obj.to_i
        dt       = time_obj.strftime("%Y-%m-%d")

        tmp_dir_base  = @config.get(PATRIOT_TMP_DIR_KEY, DEFAULT_PATRIOT_TMP_DIR)

        cid = do_fork(command, dt, ts, tmp_dir_base)
        tmpdir = tmp_dir(cid, dt, ts, tmp_dir_base)

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

