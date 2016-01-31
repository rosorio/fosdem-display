use strict;
use File::Temp qw( :POSIX );
use Text::CSV;
use Data::Dumper qw(Dumper); 
use POSIX qw(strftime);
use Text::FIGlet;
#use Time::HiRes qw( usleep );
use Term::ANSIScreen qw(cls);
use Encode qw(decode encode);

my $debug = 0;
my $curr_conf = 0;
my $clear_screen = cls();
my $filbanner = Text::FIGlet->new(-f=>"banner");
my $filtext = Text::FIGlet->new();

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

if (! @ARGV) {
	print "Usage: $0  <schedule_file.csv>\n";
	exit(1);
}

my $program = load_and_sort_schedule($ARGV[0]);

$curr_conf = -1;
my $conf_text;


while(1) {
	my $time = time();
	my $text="";
	my $ptime="";
	my $rtime=0;
	my $deco="";

 	my $new_conf = get_current_conf($program);
	if ($new_conf != $curr_conf) {
		if ($new_conf == -1) {
			if ($curr_conf != -1 && $curr_conf < @$program) {
				$conf_text  =  "$program->[$curr_conf + 1]{'desc'}\n";
				$conf_text .=  $filtext->figify(-A=>"$program->[$curr_conf+1]{'speaker'}\n");
			} else	{
				$curr_conf = -1;
			}
			
		} else {
			$curr_conf = $new_conf;
			$conf_text  =  "$program->[$curr_conf]{'desc'}\n";
			$conf_text .=  $filtext->figify(-A=>"$program->[$curr_conf]{'speaker'}\n");
		}
			
	}

	if ($curr_conf != -1) {
		if($new_conf == -1) {
			$rtime = $program->[$curr_conf + 1]{'tstamp'} - $time;
			$ptime = sprintf("ETA %02d:%02d",int($rtime / 60),($rtime % 60));
			$text = "$conf_text\n" . $filbanner->figify(-A=>"$ptime"); 
		} else {
			$rtime = $program->[$curr_conf]{'endstamp'} - $time;
			if($rtime < 300) {
				$deco="";
				if($rtime % 2) {
					$deco =" << "
				}	
			}
			$ptime = sprintf(" >> %02d:%02d ${deco}",int($rtime / 60),($rtime % 60));
			$text = "$conf_text\n" . $filbanner->figify(-A=>"$ptime");
		}

	}
	print $clear_screen;
	print ~~"$text";

	sleep 1;
}
