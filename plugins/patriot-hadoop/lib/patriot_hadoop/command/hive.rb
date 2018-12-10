module PatriotHadoop
  module Command
    class HiveCommand < Patriot::Command::Base
      declare_command_name :hive
      include PatriotHadoop::Ext::Hive

      command_attr :hive_ql, :output_prefix, :compression, :exec_user, :props, :name_suffix

      def job_id
        job_id = "#{command_name}"
        job_id = "#{job_id}_#{@name_suffix}" unless @name_suffix.nil?
        return job_id
      end


      def execute
        @logger.info "start hive"

        opt = {}
        opt[:udf] = @udf unless @udf.nil?
        opt[:props] = @props unless @props.nil?

        output_prefix = @output_prefix.nil? ? File.join('/tmp', job_id()) : @output_prefix
        output_directory = File.dirname(output_prefix)
        if not Dir.exist?(output_directory)
          FileUtils.mkdir_p(output_directory)
        end

        tmpfile = output_prefix + '.hql'
        _create_hivequery_tmpfile(@hive_ql, tmpfile, opt)
        output_file = _create_output_filename(output_prefix, @compression)

        execute_hivequery(tmpfile, output_file, @exec_user)

        if File.zero?(output_file)
          @logger.warn "#{@hive_ql} generated empty result"
          return
        end

        @logger.info "end hive"
      end


      # true / 'gzip' / 'bzip2' are available.
      def _create_output_filename(output_prefix, compression)
        output_file = output_prefix + '.tsv'
        case compression
        when true, 'gzip'
          output_file += '.gz'
        when 'bzip2'
          output_file += '.bz2'
        end
        return output_file
      end


      def _create_hivequery_tmpfile(hive_ql, tmpfile, opt={})
        hive_ql = _add_udfs(hive_ql, opt[:udf]) if opt.has_key?(:udf)
        hive_ql = "#{_set_hive_property_prefix(opt[:props])}#{hive_ql}" if opt.has_key?(:props)
        File.write(tmpfile, hive_ql)
      end


      def _set_hive_property_prefix(props={})
        return "" if props.nil?
        return props.map{|k,v| "set #{k}=#{v};"}.join
      end


      def _add_udfs(hive_ql, udfs)
        return hive_ql if udfs.nil?
        register = ""
        udfs = [udfs] unless udfs.is_a?(Array)
        udfs.each do |udf|
          register += "add jar #{udf['jar']};"
          functions = udf['functions']
          functions = [functions] unless functions.is_a?(Array)
          functions.each do |f|
            register += "create temporary function #{f['name']} as \"#{f['class']}\";"
          end
        end
        return "#{register}#{hive_ql}"
      end

    end
  end
end
