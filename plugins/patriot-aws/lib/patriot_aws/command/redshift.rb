=begin

sample_select.pbc
--
redshift {
  name "select_from_redshift"
  name_suffix _date_
  inifile '/path/to//redshift.ini'
  query 'select * from test_table'
  options :with_header => true, :delimiter => "\t"
}

sample_copy.pbc
--
redshift {
  name "s3_to_redshift"
  name_suffix _date_
  inifile '/path/to/redshift.ini'
  pre_statement <<-EOS
    DELETE FROM #{schema}.#{table} WHERE ymd=#{date}
  EOS
  query <<-EOS
    COPY #{schema}.#{table}
    FROM '#{s3_path}'
    ACCESS_KEY_ID '%{access_key_id}'
    SECRET_ACCESS_KEY '%{secret_access_key}'
    delimiter '\t'
    gzip
  EOS
}

$ cat redshift.ini
[connection]
host     = staging.xxxxxxxxxxxxx.ap-northeast-1.redshift.amazonaws.com
user     = staging
password = staging
dbname   = staging
port     = 5439

[s3credentials]
access_key_id     = #{access_key_id},
secret_access_key = #{secret_access_key}
=end

require 'pg'

module PatriotAWS
  module Command
    class RedshiftCommand < Patriot::Command::Base
      declare_command_name :redshift
      include PatriotAWS::Ext::AWS

      command_attr :name, :name_suffix, :inifile, :options, :pre_statement, :query

      def job_id
        job_id = "#{command_name}_#{@name}_#{@name_suffix}"
        job_id
      end

      # @see Patriot::Command::Base#configure
      def configure
        @name_suffix ||= _date_
        self
      end

      def execute
        @logger.info 'start redshift query...'
        @options ||= {}

        ini = IniFile.load(@inifile)
        raise Exception, 'inifile not found.' if ini.nil?
        raise Exception, 'query is not set.'  if @query.nil?

        _set_options

        begin
          # replace variables
          if ini['s3credentials']
            @query = @query % ini['s3credentials'].symbolize_keys
          end

          conn = PG::Connection.new(
            ini['connection'].symbolize_keys
          )

          res = {}
          conn.transaction do |conn|
            conn.exec(@pre_statement) unless @pre_statement.nil? || @pre_statement.empty?
            res = conn.exec(@query)
          end

          output_arr = Array.new
          if res then
            res.each_with_index do |r, idx|
              # print header
              if @options[:with_header] && idx == 0
                output_arr.push r.keys.join(@options[:delimiter])
              end

              output_arr.push r.values.join(@options[:delimiter])
            end
          end

          puts output_arr.join("\n")
        # rescue PGError => ex
        #   # may cause PGError when connection setting is invalid
        #   # e.g.
        #   # PG::ConnectionBad -> could not translate host name "test" to address: nodename nor servname provided, or not known
        #   print(ex.class," -> ",ex.message)
        #
        #   raise PGError
        # rescue => ex
        #   # Other Error process
        #   print(ex.class," -> ",ex.message)
        ensure
          conn.close if conn
        end
      end

      # @private
      # set default option parameters
      def _set_options
        @options[:with_header]  = false if @options[:with_header].nil?
        @options[:delimiter]    = "\t"  if @options[:delimiter].nil?
      end
      private :_set_options
    end
  end
end
