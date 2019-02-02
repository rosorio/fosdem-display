use POSIX qw(strftime);
use Gtk2 '-init';
use Text::CSV;
use Encode qw(decode encode);
use Text::Wrap;
use strict;

use constant {
    FONT_SIZE_SPEAKER     => 20000,
    FONT_SIZE_DATE        => 20000,
    FONT_SIZE_CONFTEXT    => 50000,
    FONT_SIZE_REM_TIME    => 30000,
    FONT_SIZE_GREEN_TIME  => 50000,
    FONT_SIZE_ORANGE_TIME => 55000,
    FONT_SIZE_RED_TIME    => 60000,
    TRUE                  => 1,
    FALSE                 => 0,
    FOSDEM_IMAGE          => "fosdem2.png"
};

my $conf_text    = "";
my $conf_speaker = "";
my $ltime;
my $logo;
my $remtime;
my $confname;
my $confspeaker;
my $program;
my $white = Gtk2::Gdk::Color->new(0xFFFF, 0xFFFF, 0xFFFF);
my $program;
$Text::Wrap::columns = 42;

sub updatedisplay()
{
    my $time = time();
    my $rem_time;
    my $deco;
    my $current;
    my $next;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      localtime();
    my $datestring =
        strftime '<span font_size="'
      . FONT_SIZE_DATE
      . '" color="black">'
      . "%d/%m/%Y %H:%M"
      . '</span>', localtime;
    $ltime->set_markup($datestring);

    $current = get_current_conf($program);
    $next = get_next_conf($program) if ($current == -1);

    if ($next == -1 && $current == -1) {
        print "This is the end\n";
        return 1;
    }

    $conf_text =
      wrap('', '', $program->[$current != -1 ? $current : $next]{'desc'});
    $conf_speaker = $program->[$current != -1 ? $current : $next]{'speaker'};

    $confname->set_markup('<span font_size="'
          . FONT_SIZE_CONFTEXT
          . '" color="black">'
          . $conf_text
          . '</span>');
    $confspeaker->set_markup('<span font_size="'
          . FONT_SIZE_SPEAKER
          . '" color="black"> by '
          . $conf_speaker
          . '</span>');

    $deco = '<span font_size="' . FONT_SIZE_GREEN_TIME . '" color="green">';

    my $rtime;
    if ($current == -1) {
        $rtime    = $program->[$next]{'tstamp'} - $time;
        $rem_time = sprintf(
            '<span font_size="'
              . FONT_SIZE_RED_TIME
              . '" color="blue">'
              . "Starts in %02d mn %02d sec</span>",
            int($rtime / 60),
            ($rtime % 60)
        );
    } else {
        my $longtime =
          int($program->[$current]{'endstamp'}) -
          int($program->[$current]{'tstamp'});
        $rtime = $program->[$current]{'endstamp'} - $time;
        my $sptime = $time - $program->[$current]{'tstamp'};
        $deco =
          '<span font_size="' . FONT_SIZE_ORANGE_TIME . '" color="orange">'
          if ($rtime < 900);
        $deco = '<span font_size="' . FONT_SIZE_RED_TIME . '" color="red">'
          if ($rtime < 300);
        $rem_time = sprintf(
            " ${deco} %02d mn %02d sec </span> "
              . '<span font_size="'
              . FONT_SIZE_REM_TIME
              . '" color="black">' . ' / '
              . '%02d mn %02d sec</span>',
            int($rtime / 60),
            ($rtime % 60),
            int($sptime / 60),
            ($sptime % 60)
        );
    }

    $remtime->set_markup($rem_time);

    1;
}

sub get_current_conf
{
    my $list = shift;
    my $epoc = time();
    my $pos  = 0;
    my $len  = scalar @$list;

    while ($pos < $len) {
        if ($list->[$pos]{'tstamp'} <= $epoc) {
            if (($list->[$pos]{'tstamp'} + $list->[$pos]{'duration'}) > $epoc) {
                return $pos;
            }
        }
        $pos++;
    }
    return -1;
}

sub get_next_conf
{
    my $list = shift;
    my $epoc = time();
    my $pos  = 0;
    my $len  = scalar @$list;

    while ($pos < $len) {
        if ($list->[$pos]{'tstamp'} > $epoc) {
            return $pos;
        }
        $pos++;
    }
    return -1;
}

sub load_and_sort_schedule
{
    my $file = shift;
    my @myprogram;

    open my $fh, "<", $file or die "$file: $!";
    my $csv = Text::CSV->new({binary => 1, auto_diag => 1,});

    while (<$fh>) {
        chomp;
        if ($csv->parse($_)) {
            my $rec  = {};
            my @rows = $csv->fields();
            $rec->{'desc'}    = @rows[1];
            $rec->{'speaker'} = Encode::encode("ISO-8859-1", @rows[2]);
            $rec->{'date'}    = @rows[4];
            $rec->{'time'}    = @rows[5];
            my ($hour, $min, $sec) = split(":", @rows[7]);
            $rec->{'duration'} = (($hour * 60) + $min) * 60;

            my @date = split("-", $rec->{'date'});
            my @time = split(":", $rec->{'time'});

            $rec->{'tstamp'} = POSIX::mktime(
                @time[2], @time[1], @time[0], @date[2],
                @date[1] - 1,
                @date[0] - 1900
            );
            $rec->{'endstamp'} = $rec->{'tstamp'} + $rec->{'duration'};
            push @myprogram, $rec;
        }
    }

    my @sort = sort { $a->{'tstamp'} <=> $b->{'tstamp'} } @myprogram;
    return (\@sort);
}

my $window;
my $screen;
my $table;
$program = load_and_sort_schedule($ARGV[0]);

$window = Gtk2::Window->new('toplevel');
$screen = $window->get_screen;

# Build the graphical objects
$ltime    = new Gtk2::Label("");
$logo     = Gtk2::Image->new_from_file(FOSDEM_IMAGE);
$confname = new Gtk2::Label("&&");
##$confname->set_line_wrap(TRUE);
##$confname->set_size_request($screen->get_width, 400);
$confname->set_justify('center');
$remtime     = new Gtk2::Label("ETA");
$confspeaker = new Gtk2::Label("******");
$confspeaker->set_justify('center');

$table = Gtk2::Table->new(4, 2, FALSE);
$table->attach_defaults($confname,    0, 2, 0, 1);
$table->attach_defaults($confspeaker, 0, 2, 1, 2);
$table->attach_defaults($remtime,     0, 2, 2, 3);
$table->attach_defaults($ltime,       0, 1, 3, 4);
$table->attach_defaults($logo,        1, 2, 3, 4);

# Start the main window
$window->resize($screen->get_width, $screen->get_height);
$window->modify_bg('normal', $white);
$window->add($table);
$window->show_all;

# Create a timer to refresh the display
Glib::Timeout->add(200, \&updatedisplay);

# Start the app
Gtk2->main;
