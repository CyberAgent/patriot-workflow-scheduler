require 'date'
module Patriot
  module Util
    # module for handling cron format interval
    module CronFormatParser

      # start 00:00:00 everyday
      DEFAULT_CRON_FIELD = "0 0 * * *" 

      # a key word to indicate interval in which jobs are executed on the end of every month
      END_OF_EVERY_MONTH = 'end_of_every_month'

      # the list of week days
      WEEKS   = 0.upto(6).to_a
      # the list of months
      MONTHS  = 1.upto(12).to_a
      # the list of days
      DAYS    = 1.upto(31).to_a
      # the list of hours
      HOURS   = 0.upto(23).to_a
      # the list of minutes
      MINUTES = 0.upto(59).to_a

      DAY_IN_SECOND = 60 * 60 * 24

      # expand a given date to the array of time which should be executed in case of a given cron field
      # @param date [Time] target datetime
      # @param cron_field [String] interval in cron format
      # @return [Array<Time>] a list of datetime which match the cron format
      def expand_on_date(date, cron_field = nil)
        cron_field = DEFAULT_CRON_FIELD if cron_field.nil? || cron_field.empty?
        if cron_field == END_OF_EVERY_MONTH
          return (date + DAY_IN_SECOND).day == 1 ? [date] : []
        end
        field_splits = cron_field.split
        raise "illegal cron field format #{cron_field}" unless field_splits.size == 5
        minute, hour, day, month, week = field_splits
        return [] unless is_target_day?(date, day, month, week)
        return target_hours(hour).map do |h|
          target_minutes(minute).map do |m|
            Time.new(date.year, date.month, date.day, h, m, 0)
          end
        end.flatten
      end

      # check a given date is a target or not
      # @param date [Time] a datetime to be checked
      # @param day [String] day field in cron format
      # @param month [String] month field in cron format
      # @param week [String] week field in cron format
      def is_target_day?(date, day, month, week)
        unless month == "*" || parse_field(month, MONTHS).to_a.include?(date.month)
          return false 
        end
        return true if day == "*" && week == "*"
        target_weeks = parse_field(week, WEEKS)
        return parse_field(day, DAYS).include?(date.day) if week == "*"
        return parse_field(week, WEEKS).include?(date.wday)
      end

      # @param hour [String] hour field in cron format
      # @return [Array<Integer>] a target hours for the given hour specification
      def target_hours(hour)
        return parse_field(hour, HOURS)
      end

      # @param minute [String] minute field in cron format
      # @return [Array<Integer>] a target minutes for the given minute specification
      def target_minutes(minute)
        return parse_field(minute, MINUTES)
      end

      # select elements which match a given field from a given domain
      # @param field [String] one of the cron field
      # @param domain [Array<Integer>] the domain of the field
      # @return [Array<Integer>] a list of the domain elements match with the field
      def parse_field(field, domain)
        field = field.split("/")
        raise "illegal cron field format #{field.join("/")}" unless field.size <= 2 
        range = []
        if field[0] == "*"
          range = domain 
        else
          range = field[0].split(",").map do |r|
            subrange = r.split("-")
            if subrange.size == 1
              subrange[0].to_i
            elsif subrange.size == 2 
              subrange[0].to_i.upto(subrange[1].to_i).to_a
            else
              raise "illegal cron field format #{field.join("/")}" 
            end
          end.flatten
        end
        return range if field.size == 1
        interval = field[1].to_i
        filtered_range = []
        range.each_with_index do |r,i| 
          filtered_range << r if (i % interval) == 0
        end
        return filtered_range
      end

    end
  end
end
