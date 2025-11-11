#!/usr/local/bin/perl -w
# AUML (v0.1) Winikoff April 2003

# configuration stuf
$initvpos=5;			# initial vertical position
$agwidth=100; 			# width of box with agent name
$agsep=30;   			# separation between boxes
$agboxheight=20;		# Height of the agent box
$messageheight=20;		# vertical skip between messages
$agboxskip=$agboxheight+5+$messageheight;	# Vertical space after agent/role name boxes
$boxskip=15;			# Vertical space after closing box (if protocol continues)
$nextskip=15;			# Vertical space after a dashed next line in a box
$tagwidth=30;			# Width of the tag on boxes
$inittagwidth=120;		# Width of the tag for the initial protocol box
$tagheight=20;			# Height of the tag on boxes
$boxtop=$tagheight+5;		# Vertical space after opening of box
$inittagheight=20;		# Height of the tag for the initial protocol box
$initboxtop=$inittagheight+5; 	# vertical space after opening of initial protocol box
$tagsnip=7;			# The amount "snipped" off the tag of boxes (width=height)
$interboxgap=7;			# Space between nested boxes
$wishexec="/usr/local/bin/wish"; # Location of the wish executable
$nextlinewidth=2;		# Width of the "next" dashed line
$boxlinewidth=2;		# Width of the boxes
$textup=10;			# How far up text is moved so as not to be on top of lines
$textmup=8;			# Same, but for messages use a different (lower) shift
# end config

# XXX should be computed
$offset=20;		# space at left (for boxes)
#$offset = $interboxgap * numboxes

$line = 0; # input line number
# used to create space between agents/roles and the first message
# init = 1 - processing agent roles
# init = 2 - processing closing boxes
$init = 1; 
$dash = "";

if (!defined($ARGV[0])) {
	print STDERR "Usage: auml.pl filename\n\n";
	exit 1;
}

open INPUT,"$ARGV[0]";
open OUT,">$ARGV[0].tk";

print OUT "#!$wishexec\nset epsfile \"$ARGV[0].eps\"\n\n";
print OUT <<'END';
canvas .c
frame .f
button .f.quit -text "Quit" -command finishup
pack .f -side top
pack .f.quit -fill x -side left
pack .c -side bottom -fill both -expand 1
focus .c
proc finishup {} {
        global epsfile
        set bb [.c bbox all]
        if {[llength $bb] == 0} return
        set x1 [lindex $bb 0]
        set y1 [lindex $bb 1]
        set w [expr [lindex $bb 2]-$x1]
        set h [expr [lindex $bb 3]-$y1]
        .c postscript -file $epsfile  -x $x1 -y $y1 -height $h -width $w
	exit
}
END

%agents = ();  # number of agent (first, second)
%agentsy = (); # y position of roles
@boxes = ();   # stack of boxes - each box stores "type,y"
$agentnum=0;   # next available agent number
$vpos = $initvpos;    # vertical position

while (<INPUT>) {
	$line++;
	chomp;
	($a,$b,$c,@d) = split " ";
	$d = join " ", @d;
	next if !defined($a);
	if ($a eq "agent" || $a eq "role" || $a eq "invis") {
		$c = $c . " " . $d if defined($d);
		print OUT "# agent $b ($c)\n";
		$agents{$b} = $agentnum;
		$agentsy{$b} = -1;
		$pos = ($agwidth/2) + ($agentnum*($agwidth+$agsep)) + $offset;
		$apos = $pos - ($agwidth/2);
		if ($a eq "agent" || $a eq "role") {
			$agentsy{$b} = $vpos;
			$x2 = $apos + $agwidth;
			$y2 = $vpos+$agboxheight-$textup;
			$y3 = $vpos+$agboxheight;
			print OUT ".c create rectangle $apos $vpos $x2 $y3\n";
			$c =~ s/\[/\\\[/g;
			$c =~ s/\]/\\\]/g;
			$c =~ s/\$/\\\$/g;
			print OUT ".c create text $pos $y2 -text \"$c\"\n";
		}
		$agentnum++;
		$init=1;
	} elsif ($a eq "backup") {
		$vpos = $vpos-$messageheight;
	} elsif ($a eq "message") {
		$vpos = $vpos + $agboxskip if $init==1; # move down if first message
		$vpos = $vpos + $boxskip if $init==2; # move down if message after alt
		$init = 0 if $init>0;
		print OUT "# message $b $c $d\n";
		$num_from = $agents{$b};
		$num_to  = $agents{$c};
		if ($num_to == $num_from) {
			print STDERR "Can't send a message to self - line $line\n";
		} else {
				$pos_from = ($agwidth/2) + ($num_from*($agwidth+$agsep)) +$offset;
				$pos_to = ($agwidth/2) + ($num_to*($agwidth+$agsep)) +$offset;
				$pos_text = ($pos_to+$pos_from)/2;
				print OUT ".c create line $pos_from $vpos $pos_to $vpos -arrow last\n";
				$vpos2 = $vpos-$textmup;
				# quote characters that are interpreted by Tcl/Tk
				$d =~ s/\[/\\\[/g;
				$d =~ s/\]/\\\]/g;
				$d =~ s/\$/\\\$/g;
				print OUT ".c create text $pos_text $vpos2 -text \"$d\"\n";
				$vpos = $vpos+$messageheight;
		}
    	} elsif ($a eq "start") {
		$c = $c . " " . $d if defined($d);
		$b = $b . " " . $c if defined($c);
		push @boxes, "$b,$vpos";
		$vpos += $initboxtop;
		$dash = "-dash -"; # Make lifelines dashed, not solid
	} elsif ($a eq "box") {
		$vpos = $vpos + $agboxskip if $init==1; # move down if first message
		$vpos = $vpos + $boxskip if $init==2; # move down if message after alt
		$init = 0 if $init>0;
		push @boxes, "$b,$vpos";
		$vpos += $boxtop;
	} elsif ($a eq "next") {
		$x1 = $interboxgap*(1+$#boxes); 
		$x2 = $agentnum*($agwidth+$agsep)+$offset-($interboxgap*$#boxes);
		print OUT ".c create line $x1 $vpos $x2 $vpos -width $nextlinewidth -dash -\n";
		$vpos += $nextskip;
	} elsif (($a eq "end") || ($a eq "finish")) {
		$x1 = $interboxgap*(1+$#boxes); 
		$x2 = $agentnum*($agwidth+$agsep)+$offset-($interboxgap*$#boxes);
		$l = pop @boxes;
		($type,$y) = split ",", $l;
		if (defined($b) && !($type eq $b) && !($a eq "finish")) {
			print STDERR "Error: $b doesn't match up on line $line - type=$type!\n";
		}
		print OUT ".c create rectangle $x1 $y $x2 $vpos -width $boxlinewidth\n";
		$extrax = 0;
		$extrax = $inittagwidth-$tagwidth if $a eq "finish";
		$extray = 0;
		$extray = $inittagheight-$tagheight if $a eq "finish";
		$x3 = $x1+ $tagwidth +$extrax;
		$x4 = $x1+$tagwidth +$extrax-$tagsnip;
		$y2 = $y+$tagheight+$extray-$tagsnip;
		$y3 = $y+$tagheight+$extray;
		$xtext = ($x1+$x3)/2;
		$ytext = $y3-$textup;
		print OUT ".c create polygon $x1 $y $x3 $y $x3 $y2 $x4 $y3 $x1 $y3 -fill {} -outline black -width $boxlinewidth\n";
		print OUT ".c create text $xtext $ytext -text \"$type\"\n";
		$vpos += $interboxgap if !($a eq "finish");
		$init =2;
# ** split R SR
# ** join R SR
# ** change R SR NR
# ** endrole R

	} else {
		print STDERR "Ignored input on line $line\n";
	}
}
close INPUT;

print OUT "\n# Create life lines\n";
foreach $k (keys %agents) {
	$pos_from = ($agwidth/2) + ($agents{$k}*($agwidth+$agsep)) +$offset;
	$y = $agentsy{$k}+$agboxheight; 
	print OUT ".c create line $pos_from $y $pos_from $vpos $dash\n" 
		unless $agentsy{$k}==-1;
}
print OUT <<'END';
# uncomment for automatic printout and quit
finishup
END

close OUT;

