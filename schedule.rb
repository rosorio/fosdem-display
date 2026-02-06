require "gtk3"
require 'date'
require_relative 'schedule_logic'

@builder
def get_object(name)
    return @builder.get_object(name)
end
date="2026-02-06"
tz="CET"
text_schedule = [
    ["15:00",20,"Thibault Payet","The state of gaming on FreeBSD"],
    ["15:25",20,"Valgrind for DragonFly/Net/Open BSD?","Paul Floyd"],
    ["15:50",25,"smolBSD: boots faster than its shadow!","Emile 'iMil' Heitor, Pierre Pronchery"],
    ["16:20",20,"(Re)Building a next gen system package Manager and Image management tool","Till Wegmüller"],
    ["16:45",25,"Dancing with Daemons: Porting Swift to FreeBSD","Evan Wilde, Michael Chiu"],
    ["17:15",25,"Bringing BSD Applications on Linux container platforms with urunc","Charalampos Mainas, Anastassios Nanos"],
    ["17:45",20,"Optimising kernels and file systems for PostgreSQL, a cross-project talk","Thomas Munro"],
    ["18:15",20,"Browsing Git repositories with gotwebd","Stefan Sperling, Omar Polo"],
    ["18:40",20,"Securing your network with OpenBSD","Polarian"]
]

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
