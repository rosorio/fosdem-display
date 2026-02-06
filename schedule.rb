require "gtk3"
require 'date'

@builder
def get_object(name)
    return @builder.get_object(name)
end
date="2026-01-31"
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

@schedule = []

text_schedule.each {|current|
    start_time = DateTime.strptime("#{date} #{current[0]} CET","%Y-%m-%d %H:%M %Z")
    end_time = start_time + Rational(current[1],24*60)

    @schedule.push([start_time, end_time, current[2], current[3]])
}

builder_file = "#{File.expand_path(File.dirname(__FILE__))}/schedule.ui"
@builder = Gtk::Builder.new(:file => builder_file)
window = get_object("window")
screen = Gdk::Screen.default


@current_talk = 0;
GLib::Timeout.add(1000) do
    now = DateTime.now;
    while @current_talk < @schedule.length() && @schedule[@current_talk][0] < now && @schedule[@current_talk][1] < now
            @current_talk += 1
    end

    if @current_talk < @schedule.length()
        if (@schedule[@current_talk][0] < now)
            delay = ((@schedule[@current_talk][1]-now) * 24 * 60 * 60).to_i
        else
            delay = ((@schedule[@current_talk][0] - now) * 24 * 60 * 60).to_i
        end
        get_object("talk_time").set_text(format("%02d:%02d", delay / 60, delay % 60 ))
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
