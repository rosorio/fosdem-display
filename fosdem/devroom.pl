use strict;
use POSIX qw(strftime);
use Gtk2 '-init';
use constant false => 0;
use constant true  => 1;
use Text::CSV;
use Encode qw(decode encode);


my $curr_conf = -1;
my $program;
my $fenetre;
my $screen;
my $table;
my $ltime;
my $logo;
my $remtime;
my $confname;
my $confspeaker;
my $conf_text = "";
my $conf_speaker = "";
my $font_size_date          = 30000;
my $font_size_speaker       = 40000;
my $font_size_conf_text     = 60000;

my $font_size_rem_time      = 100000;
my $font_size_green_time    = 100000;
my $font_size_orange_time   = 110000;
my $font_size_red_time      = 120000;


sub updatedisplay() {
	my $time = time();
	my $rem_time;
	my $deco;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	my $datestring = strftime '<span font_size="' . $font_size_date . '" color="black">' . "%d/%m/%Y %H:%M" . '</span>', localtime;
	$ltime->set_markup ($datestring);

	my $new_conf = get_current_conf($program);
        if ($new_conf != $curr_conf) {
                if ($new_conf == -1) {
                        if ($curr_conf != -1 && $curr_conf < @$program) {
                                $conf_text  =  $program->[$curr_conf + 1]{'desc'};
                                $conf_speaker =  $program->[$curr_conf+1]{'speaker'};
                        } else  {
                                $curr_conf = -1;
                        }

                } else {
			
                        $curr_conf = $new_conf;
                        $conf_text  =  $program->[$curr_conf]{'desc'};
                        $conf_speaker =  $program->[$curr_conf]{'speaker'};
                }
		$confname->set_markup('<span font_size="' . $font_size_conf_text . '" color="black">' . $conf_text . '</span>'); 
		$confspeaker->set_markup('<span font_size="' . $font_size_speaker . '" color="black"> by ' . $conf_speaker . '</span>');

        }
	$deco='<span font_size="' . $font_size_green_time . '" color="green">';
	if ($curr_conf != -1) {
		my $rtime;
		 if($new_conf == -1) {
			$rtime = $program->[$curr_conf + 1]{'tstamp'} - $time;
			$rem_time = sprintf('<span font_size="' . $font_size_rem_time . '" color="blue">' . "Start in %02d:%02d</span>",int($rtime / 60),($rtime % 60));
		} else {
			my $longtime =  int($program->[$curr_conf]{'endstamp'}) - int($program->[$curr_conf]{'tstamp'});
			$rtime = $program->[$curr_conf]{'endstamp'} - $time;
			$deco ='<span font_size="' . $font_size_orange_time . '" color="orange">' if($rtime < 900);
			$deco ='<span font_size="' . $font_size_red_time . '" color="red">' if($rtime < 300);
			$rem_time = sprintf(" ${deco} %02d:%02d </span> " .'<span font_size="' . $font_size_rem_time . '" color="black">/ %02d:%02d</span>',int($rtime / 60),($rtime % 60),
			int($longtime/ 60),($longtime% 60));
		}
	}
		
	$remtime->set_markup($rem_time);


	1;
}

sub get_current_conf
{
        my $list = shift;
        my $epoc = time();
        my $pos = 0;
        my $len = @$list;

        while ( $pos < $len ) {
                if($list->[$pos]{'tstamp'} <= $epoc) {
                        if(($list->[$pos]{'tstamp'} + $list->[$pos]{'duration'}) > $epoc) {
                                return $pos;
                        }
                }
                $pos ++;
        }
        return -1;
}

sub load_and_sort_schedule {
        my $file = shift;
        my @program;

        open my $fh, "<", $file or die "$file: $!";
        my $csv = Text::CSV->new ({ binary    => 1, auto_diag => 1, });

        while (<$fh>) {
                chomp;
                if ($csv->parse($_)) {
                        my $rec = {};
                        my @rows = $csv->fields();
                        $rec->{'desc'}     = @rows[1];
                        $rec->{'speaker'}  = Encode::encode("ISO-8859-1",@rows[2]);
                        $rec->{'date'}     = @rows[4];
                        $rec->{'time'}     = @rows[5];
                        my ($hour,$min,$sec) = split(":", @rows[7]);
                        $rec->{'duration'} = (($hour * 60) + $min) * 60 ;

                        my @date = split("-",$rec->{'date'});
                        my @time = split(":",$rec->{'time'});

                        $rec->{'tstamp'} = POSIX::mktime(@time[2], @time[1], @time[0],
                                                     @date[2], @date[1]-1, @date[0]-1900);
                        $rec->{'endstamp'} = $rec->{'tstamp'} + $rec->{'duration'};
                        push @program, $rec;
                }
        }

        my @sort = sort { $a->{'tstamp'} <=> $b->{'tstamp'} } @program;
        return (\@sort);
}

$program = load_and_sort_schedule($ARGV[0]);

$fenetre = Gtk2::Window->new('toplevel');
$screen = $fenetre->get_screen;
$fenetre->resize($screen->get_width,$screen->get_height);
$table = Gtk2::Table->new (4, 2, false);
$ltime = new Gtk2::Label("");
$logo  = Gtk2::Image->new_from_file("./fosdem2.png");
$confname = new Gtk2::Label("&&&&&&&");
$confname->set_line_wrap(true);
$remtime = new Gtk2::Label("ETA");


$confspeaker = new Gtk2::Label("******");
$confspeaker->set_justify('left');


$table->attach_defaults($confname,0,2,0,1);
$table->attach_defaults($confspeaker,0,2,1,2);
$table->attach_defaults($remtime,0,2,2,3);
$table->attach_defaults($ltime,0,1,3,4);
$table->attach_defaults($logo,1,2,3,4);;

Glib::Timeout->add(200,\&updatedisplay);

$fenetre->add($table);
$fenetre->show_all;

Gtk2->main;
