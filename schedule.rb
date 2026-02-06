require "gtk3"
require 'date'
require 'json'
require_relative 'schedule_logic'

@builder
def get_object(name)
    return @builder.get_object(name)
end

# Load schedule from JSON file
schedule_file = "#{File.expand_path(File.dirname(__FILE__))}/schedule.json"
schedule_data = JSON.parse(File.read(schedule_file))

date = schedule_data["date"]
tz = schedule_data["timezone"]
text_schedule = schedule_data["talks"].map do |talk|
    [talk["time"], talk["duration"], talk["speaker"], talk["title"]]
end

@schedule = ScheduleLogic.parse_schedule(text_schedule, date, tz)

builder_file = "#{File.expand_path(File.dirname(__FILE__))}/schedule.ui"
@builder = Gtk::Builder.new(:file => builder_file)
window = get_object("window")
window.signal_connect("destroy") { Gtk.main_quit }
screen = Gdk::Screen.default


@current_talk = 0;
GLib::Timeout.add(1000) do
    now = DateTime.now;
    @current_talk = ScheduleLogic.find_current_talk(@schedule, now, @current_talk)

    if @current_talk < @schedule.length()
        result = ScheduleLogic.calculate_delay(@schedule, @current_talk, now)
        if result[:state] == :before
            prefix = "In "
        else
            prefix = "Left "
        end
        get_object("talk_time").set_text(format("%s%02d:%02d", prefix, result[:delay] / 60, result[:delay] % 60 ))
        get_object("talk_name").set_text(@schedule[@current_talk][2])
        get_object("talk_speaker").set_text(@schedule[@current_talk][3])
    else
        get_object("talk_time").set_text("The end")
        get_object("talk_name").set_text("That's all floks!")

    end
    get_object("current_time").set_text(now.to_s)
end

window.show_all

Gtk.main
