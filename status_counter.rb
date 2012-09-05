module StatusCounter

  class UserCounter
    def map_command
      <<-EOS
        function() {
          emit(this.user.id_str, 1);
        }
      EOS
    end

    def reduce_command
      <<-EOS
        function(key, values) {
          var count = 0;

          for(i in values) {
            count += values[i]
          }

          return count;
        }
      EOS
    end

  end

  def status_count_by_user
    counter = UserCounter.new
    statuses.map_reduce(counter.map_command, counter.reduce_command, default_mr_options)
  end


  class HourOfDayCounter
    def map_command
      'function() {
        var re = /(\d{2,2}):\d{2,2}:\d{2,2}/;
        var hour = re.exec(this.created_at)[1];

        emit(hour, 1);
      }'
    end

    def reduce_command
      <<-EOS
        function(key, values) {
          var count = 0;

          for(i in values) {
            count += values[i]
          }

          return count;
        }
      EOS
    end

  end

  def status_count_by_hday(days_ago = 7)
    date     = Date.today - days_ago
    days_ago = Time.utc(date.year, date.month, date.day)
    query = { "created_at_dt" => { "$gte" => days_ago } }

    options = default_mr_options.merge(:query => query)

    counter = HourOfDayCounter.new
    statuses.map_reduce(counter.map_command, counter.reduce_command, options)
  end

  def default_mr_options
    {:out => {:inline => 1}, :raw => true }
  end

end
