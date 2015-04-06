require 'date'
module Patriot
  module Util
    module DateUtil

      def date_format(dt, time, fmt, diff={})
        diff = {:year => 0, 
                :month => 0,
                :day => 0,
                :hour => 0,
                :min => 0,
                :sec => 0}.merge(diff)

        dt  = eval "\"#{dt}\""
        time  = eval "\"#{time}\""

        t = time.split(':')
        d = dt.split('-')
        sec = t[2].to_i + diff[:sec]
        min = t[1].to_i + diff[:min] 
        hour = t[0].to_i + diff[:hour] 
        day = d[2].to_i 
        month = d[1].to_i 
        year = d[0].to_i + diff[:year]

        min = min+ sec/60
        hour = hour + min/60
        diff[:day]= diff[:day] + hour/24  

        sec = sec%60
        min = min%60
        hour = hour%24
   
        new_dt = DateTime.new(year, month, day, hour, min,sec)
        new_dt = new_dt >> diff[:month]
        new_dt = new_dt + diff[:day]
        return new_dt.strftime(fmt)
      end

      def date_add(date, interval)
        d = to_date_obj(date)
        d = d + interval
        return d.strftime('%Y-%m-%d')
      end

      def date_sub(date, interval)
        d = to_date_obj(date)
        d = d - interval
        return d.strftime('%Y-%m-%d')
      end

      def date_add_year(date, interval)
        s = date.split("-");
        return Date.new(s[0].to_i + interval,s[1].to_i,s[2].to_i).strftime("%Y-%m-%d")
      end

      def date_sub_year(date, interval)
        s = date.split("-");
        return Date.new(s[0].to_i - interval,s[1].to_i,s[2].to_i).strftime("%Y-%m-%d")
      end

      def month_add(month, interval)
        d = to_date_obj("#{month}-01")
        d = d >> interval
        return d.strftime('%Y-%m')
      end

      def month_sub(month, interval)
        d = to_date_obj("#{month}-01")
        d = d << interval
        return d.strftime('%Y-%m')
      end

      def to_month(date)
        d = to_date_obj(date)
        return d.strftime('%Y-%m')
      end

      def to_start_of_month(date)
        s = date.split("-");
        return Date.new(s[0].to_i,s[1].to_i,1).strftime("%Y-%m-%d")
      end

      def to_end_of_month(date)
        s = date.split("-");
        return ((Date.new(s[0].to_i,s[1].to_i,1)>>1)-1).strftime("%Y-%m-%d")
      end

      def to_end_of_last_month(date)
        d = to_date_obj(date)
        d = d - d.day
        return d.strftime('%Y-%m-%d')
      end

      def days_of_week(date)
        d = to_date_obj(date)
        return d.wday
      end

      def days_of_month(month)
        s = month.split('-')
        y = s[0].to_i
        m = s[1].to_i
        return 1.upto(31).map{|d| Date.new(y,m,d).strftime('%Y-%m-%d') if Date.valid_date?(y,m,d)}.compact
      end

      def days_of_month_until(dt)
        s = dt.split('-')
        y = s[0].to_i
        m = s[1].to_i
        d = s[2].to_i
        return 1.upto(d).map{|d| Date.new(y,m,d).strftime('%Y-%m-%d') if Date.valid_date?(y,m,d)}.compact
      end

      def to_date_obj(date)
        d = date.split('-')
        return Date.new(d[0].to_i, d[1].to_i, d[2].to_i)
      end

      def date_to_month(date)
        d = date.split('-')
        return Date.new(d[0].to_i, d[1].to_i, d[2].to_i).strftime('%Y-%m')
      end

      def hours
        return 0.upto(23).map do |h| h_str = h.to_s.rjust(2, "0") end.flatten
      end

      def validate_and_parse_dates(date)
        date_objs = date.split(",").map do |d|
          unless d.to_s =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
            raise ArgumentError, "ERROR: invalid date #{d} in #{date}"
          end
          Date.parse(d.to_s)
        end
        if date_objs.size == 1
          return [date]
        elsif date_objs.size == 2
          dates = []
          date_objs[0].upto(date_objs[1]){|d| dates << d.to_s}
          return dates
        end
        raise ArgumentError, "ERROR: invalid date #{date}"
      end
      private :validate_and_parse_dates

    end
  end
end

