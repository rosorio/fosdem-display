require 'date'

module ScheduleLogic
  def self.parse_schedule(text_schedule, date, tz)
    schedule = []
    text_schedule.each do |current|
      start_time = DateTime.strptime("#{date} #{current[0]} #{tz}", "%Y-%m-%d %H:%M %Z")
      end_time = start_time + Rational(current[1], 24 * 60)
      schedule.push([start_time, end_time, current[2], current[3]])
    end
    schedule
  end

  def self.find_current_talk(schedule, now, current_talk)
    while current_talk < schedule.length && schedule[current_talk][0] < now && schedule[current_talk][1] < now
      current_talk += 1
    end
    current_talk
  end

  def self.calculate_delay(schedule, current_talk, now)
    return nil if current_talk >= schedule.length

    if schedule[current_talk][0] < now
      # During the talk: time remaining until end
      ((schedule[current_talk][1] - now) * 24 * 60 * 60).to_i
    else
      # Before the talk: time until start
      ((schedule[current_talk][0] - now) * 24 * 60 * 60).to_i
    end
  end
end
