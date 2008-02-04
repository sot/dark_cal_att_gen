#! /usr/bin/env /proj/sot/ska/bin/perlska 


# Subroutines to generate Dark Current Attitudes
# that meet conditions for expected Zodiacal Light
# Brightness

use strict;
#use diagnostics;
#use warnings;
use POSIX;
use Date::Parse;
use Time::DayOfYear;
use Ska::Convert;
use Ska::Process;
use CGI qw/:standard/;
#use CGI::Carp qw(fatalsToBrowser);


my @attitudes;

# default limits on zodiacal brightness for testing
my $z_low_limit = 0;
my $z_up_limit = 250;

if (param()) {
#my $test = 1;
#if ($test){

# if the form blanks have been filled in, perform the requested actions

    my $date = param('date');
#my $date = "2005:250";
    my $type = param('type');
#my $type = "ATT List";
    # lower limit of zodiacal light brightness
    $z_low_limit = param('z_low');
    # upper limit of zodiacal light brightness	
    $z_up_limit = param('z_up');
    
    printList($date,$type);
    
}
else{

# if the form has not been submitted, display the form

print 'Status: 302 Moved', "\r\n", 'Location: https://icxc.harvard.edu/cgi-bin/aspect/dark_att_generator/',"\r\n\r\n";

}

##**************************************************************************
sub readAttitudes{
##**************************************************************************
# read in all dark attitudes and store them in an array
# of hashes

    open ATT, 'dark_attitudes.dat' or die $!;
    
    while (<ATT>){
	$_ =~ s/^\s*//;
	chomp $_;
	if ($_ =~ /^[0-9].*/){
	    my @currline = split(/ +/, $_);	
	    my $eq_ra = $currline[0];
		if ($eq_ra > 180){
			$eq_ra -= 360;
		}
	    my $eq_dec = $currline[1];
	    	if ($eq_dec > 180){
			$eq_dec -= 360;
		}
	    my $gal_l = $currline[2];
	    my $gal_b = $currline[3];
	    my $ec_el = $currline[4];
	    my $ec_eb = $currline[5];
	    my $n9_0 = $currline[6];
	    my $n10_3 = $currline[7];
	    my $n11_5 = $currline[8];

# This could obviously be done in fewer steps

	    my $single_att = {};
	    $single_att->{eq_ra} = $eq_ra;
	    $single_att->{eq_dec} = $eq_dec;
	    $single_att->{gal_l} = $gal_l;
	    $single_att->{gal_b} = $gal_b;
	    $single_att->{ec_el} = $ec_el;
	    $single_att->{ec_eb} = $ec_eb;
	    $single_att->{n9_0} = $n9_0;
	    $single_att->{n10_3} = $n10_3;
	    $single_att->{n11_5} = $n11_5;
	    push @attitudes, $single_att;

	}
    }
    
    close ATT;
    
}



##**************************************************************************
sub sun_ra_dec{
##**************************************************************************    
# Find Sun RA and Dec for a given Julian Day
# Code modified from http://idlastro.gsfc.nasa.gov/ftp/pro/astro/sunpos.pro
    
    my($jd) = @_;
#print "JD = $jd \n";
    my $t = ($jd - 2415020)/(36525.0);
#print "First T = $t \n";	

    my $pi = atan2(1,1)*4;
    my $dtor = $pi/180;

# sun's mean longitude

    my $l = ( 279.696678 + fmod((36000.768925*$t),360.0) )*3600.0;

# Earth anomaly
    my $me =  358.475844 + fmod((35999.049750*$t),360.0);
#print "Me = $me \n";
    my $ellcor = (6910.1 - (17.2*$t))*sin($me*$dtor) + 72.3*sin(2.0*$me*$dtor);
    $l = $l + $ellcor;
#print "Ellcor = $ellcor \n";
    
# allow for the Venus perturbations using the mean anomaly of Venus MV
    
    my $mv = 212.603219 + fmod((58517.803875*$t),360.0);
    my $vencorr = 4.8 * cos((299.1017 + $mv - $me)*$dtor) + 5.5 * cos((148.3133 +  2.0 * $mv  -  2.0 * $me )*$dtor) + 2.5 * cos((315.9433 +  2.0 * $mv  -  3.0 * $me )*$dtor) + 1.6 * cos((345.2533 +  3.0 * $mv  -  4.0 * $me )*$dtor) + 1.0 * cos((318.15   +  3.0 * $mv  -  5.0 * $me )*$dtor);
    $l = $l + $vencorr;
#print "Vencorr = $vencorr \n";
    
#  Allow for the Mars perturbations using the mean anomaly of Mars MM
    
    my $mm = 319.529425  +  fmod(( 19139.858500 * $t), 360.0 );
    my $marscorr = 2.0 * cos((343.8883 -  2.0 * $mm  +  2.0 * $me)*$dtor ) + 1.8 * cos((200.4017 -  2.0 * $mm  + $me) * $dtor);
    $l = $l + $marscorr;
#print "Marscorr = $marscorr \n";


# Allow for the Jupiter perturbations using the mean anomaly of
# Jupiter MJ
    
    my $mj = 225.328328  +  fmod(( 3034.6920239 * $t) ,  360.0 );
    my $jupcorr = 7.2 * cos(( 179.5317 - $mj + $me )*$dtor) + 2.6 * cos((263.2167  -  $mj ) *$dtor) + 2.7 * cos(( 87.1450  -  2.0 * $mj  +  2.0 * $me ) *$dtor) + 1.6 * cos((109.4933  -  2.0 * $mj  +  $me ) *$dtor);
    $l = $l + $jupcorr;
#print "Jupcorr = $jupcorr \n";
    
# Allow for the Moons perturbations using the mean elongation of
# the Moon from the Sun D
    
    my $d = 350.7376814  + fmod(( 445267.11422 * $t) , 360.0 );
    my $mooncorr  = 6.5 * sin($d*$dtor);
    $l = $l + $mooncorr;
#print "Mooncorr = $mooncorr \n";
    
# Allow for long period terms

    my $longterm  = 6.4 * sin(( 231.19  +  20.20 * $t )*$dtor);
    $l  =    $l + $longterm;
    $l  =  fmod(( $l + 2592000.0) , 1296000.0); 
    my $longmed = $l/3600.0;
    
# Allow for Aberration
    
    $l  =  $l - 20.5;
    
# Allow for Nutation using the longitude of the Moons mean node OMEGA
    
    my $omega = 259.183275 - fmod(( 1934.142008 * $t ), 360.0 );
    $l  =  $l - 17.2 * sin($omega*$dtor);

# Form the True Obliquity
    
    my $oblt  = 23.452294 - 0.0130125*$t + (9.2*cos($omega*$dtor))/3600.0;

# Form Right Ascension and Declination
    
    $l = $l/3600.0;
    my $ra  = atan2( sin($l*$dtor) * cos($oblt*$dtor) , cos($l*$dtor) );
    
    while ($ra < 0 || $ra > (2*$pi)){
	if ($ra < 0){
	    $ra += (2*$pi);
	}
	if ($ra > (2*$pi)){
	    $ra -= (2*$pi);
	}
    }
    
    my $dec = asin(sin($l*$dtor) * sin($oblt*$dtor));

#print $ra . " " . $dec . "\n";
#print $ra/$dtor . " " . $dec/$dtor . "\n";
    
    return ($ra/$dtor , $dec/$dtor);
}


##**************************************************************************
sub ra_dec_el_eb{
##**************************************************************************    
# convert eq ra,dec to ecliptic el,eb
    
    my($ai, $bi) = @_;
    
    my $pi = 3.14159265358979323846;
    my $twopi   =   2.0*$pi;
    my $fourpi  =   4.0*$pi;
    my $deg_to_rad = 180.0/$pi;
    
    
    my $equinox = '(J2000)';
    my $psi   =  0.00000000000; 
    my $stheta = 0.39777715593;
    my $ctheta = 0.91748206207;
    my $phi  = 0.0000000000;
    
    my $select = 3;
    
    my $a  = $ai/$deg_to_rad - $phi;
    my $b = $bi/$deg_to_rad;
    
    my $sb = sin($b);
    my $cb = cos($b);
    
    my $cbsa = $cb * sin($a);
    
    $b  = (-1 * $stheta * $cbsa) + ($ctheta * $sb);
    
    my $bo;
    if ($b < 1.0){
	$bo    = asin($b)*$deg_to_rad;
	
    }
    if ($b >= 1.0){
	$bo    = asin(1)*$deg_to_rad;
	
    }

    $a =  atan2( $ctheta * $cbsa + $stheta * $sb , $cb * cos($a)) ;
    
    my $ao = $a * $deg_to_rad;
    
# Here I convert from the range (-180 to 180) to (0 to 360)

    if ($ao < 0){
	$ao += 360;
    }
    if ($bo < 0){
	$bo += 360;
    }
    
    return ($ao, $bo);
}

##**************************************************************************
sub loadTable{
##**************************************************************************    
# load the comma-separated-value file containing the
# interpolated values of zodiacal brightness at 1 deg
# increments into a 2d array called @datatable
# since I push a line at a time, my table values
# are addressed as $table[L-L0 deg][ B deg]

    my @datatable;
	
    open TAB, 'table_17.csv' or die $!;

    while (<TAB>){
	if ($_ ne ""){
	    chomp $_;
	    my @lamda_line = split(/,/,$_);
	    push(@datatable,[@lamda_line]);
	}
    }
    
    close TAB;
    
    return @datatable;

}


##**************************************************************************
sub printAttitudes{
##**************************************************************************    
# for a given sun position, print an OR List or a list of attitudes
# that match the global zodiacal light constraints

    my($date, $time, $sun_ra, $sun_dec, $sun_el,$sun_eb,$type) = @_;	

    my $obscount = 1;

    if ($type eq "OR List"){
	print "<pre>\n";
	print "HDR,HDR_ID=DARK_CURR\n\n\n";
    }
    if ($type eq "ATT List"){
	print "<pre>\n";
	print "Date = $date \n";
	print "JulianDay = $time \n";
	printf "Sun RA: %3.5f Dec: %3.5f \n", $sun_ra, $sun_dec;
	printf "Sun El: %3.5f Eb: %3.5f \n", $sun_el, $sun_eb;
	print "</pre>\n";
	print "<h4>Attitudes for Dark Current Calibration</h4><br />\n";
	print "<TABLE CELLSPACING=\"6\"><TR><TH>RA</TH><TH>DEC</TH><TH>EC_EL</TH><TH>EC_EB</TH><TH>N9_0</TH><TH>N10_3</TH><TH>N11_5</TH><TH>Zodi</TH></TR>\n";
    }

# loop through the available attitudes
    for( my $j = 0; $j < scalar(@attitudes); $j++){

	my $pos_el = $attitudes[$j]{ec_el};
	my $pos_ra = $attitudes[$j]{eq_ra};
	my $pos_dec = $attitudes[$j]{eq_dec};
	my $n9_0 = $attitudes[$j]{n9_0};
	my $n10_3 = $attitudes[$j]{n10_3};
	my $n11_5 = $attitudes[$j]{n11_5};

# find L - Lsolar

	my $dll= abs($sun_el-$pos_el);
	if ($dll > 180){
		$dll = 360-$dll;
	}
	my $pos_eb = $attitudes[$j]{ec_eb};
	my $deb = abs($pos_eb);


	if ($deb > 180){
		$deb = 360 - $deb;
	}

# get a value for zodiacal light at particular attitude
# if value falls between limits, print the coordinates

	my $zodi = calcZodi($dll,$deb);

# Add the zodi information to the attitude array/hash
	$attitudes[$j]{zodi} = $zodi;
	
	if ($pos_ra < 0){
	    $pos_ra+=360;
	}

#	print "Zodi = $zodi \n";
#	print "z_up_limit = $z_up_limit \n";
#	print "z_low_limit = $z_low_limit \n";
	if ($zodi <= $z_up_limit && $zodi >= $z_low_limit){
	    if ($type eq "OR List"){
		print "OBS,\n";
		printf " ID=%05u, TARGET=(%3.7f,%3.7f,{%u}),\n", $obscount, $pos_ra, $pos_dec, $obscount;
		#printf " ID = %05u\n", $obscount;
		print " DURATION=(10.000000), PRIORITY=5, SI=ACIS-S, GRATING=NONE, SI_MODE=TE_002AE,\n";
		print " ACA_MODE=DEFAULT,\n";
		print " DITHER=(ON,0.002222,0.360000,0.000000,0.002222,0.509100,0.000000)\n\n";
		$obscount++;
	    }
	    if ($type eq "ATT List"){
		printf "<TR><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%u</TD><TD ALIGN=\"RIGHT\">%u</TD><TD ALIGN=\"RIGHT\">%u</TD><TD ALIGN=\"RIGHT\">%3.2f</TD></TR>\n", $pos_ra, $pos_dec, $pos_el, $pos_eb, $n9_0, $n10_3, $n11_5, $zodi;
	    }
	
	}
	else{
	    # if $zodi outside the specified range, and printing ATT List, print it anyway, but print zodi in red
	    if ($type eq "ATT List"){
		printf "<TR><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%3.5f</TD><TD ALIGN=\"RIGHT\">%u</TD><TD ALIGN=\"RIGHT\">%u</TD><TD ALIGN=\"RIGHT\">%u</TD><TD ALIGN=\"RIGHT\"><font color=\"red\">%3.2f</font></TD></TR>\n", $pos_ra, $pos_dec, $pos_el, $pos_eb, $n9_0, $n10_3, $n11_5, $zodi;
	    }

        }		

    }
    if ($type eq "OR List"){	
	print "</pre>\n";
    }
    if ($type eq "ATT List"){
	print "</table>\n";
    }
}

##**************************************************************************
sub calcZodi{
##**************************************************************************
# return value for zodiacal light for a given L-L0,B
# Just read the information from the zodiacal light 
# table stored in @table
    
	my($dll,$deb) = @_;
	if($dll > 180){
		return -2;
	}
	if($dll < 0){
		return -2;
	}
	if($deb > 90){
		return -2;
	}
	if($deb < 0){
		return -2;
	} 
	my $lzodi= $main::table[floor($dll)][floor($deb)];
#	print "calczodi = $lzodi \n";
	return $lzodi;
}

##**************************************************************************
sub shortJulianDate{
##**************************************************************************
# Take in the datestring of the format YYYY:DOY or YYYY-MMM-DD
# convert it to YYYY:DOY if necessary
# use Ska::Convert::date2time to get CXC time in seconds
# convert to JulianDay with division and addition
# return JulianDay

    my $datestring = $_[0];

    if($datestring =~ /^\d{4}:\d{3}$/){ 
        # if datestring looks like 2004:191
	# Do Nothing (was printing during testing)
    }
    elsif($datestring =~ /^\d{7}$/){ 
	# if datestring looks like 2004191
	# insert colon to make it look like 2004:191
	$datestring = substr($datestring, 4, 0, ":");

    }
    elsif($datestring =~ /^\d{4}-*\w{3}-*\d{2}$/){
	# if datestring looks like 2004-MAR-20
	# strip out the dashes
	$datestring =~ s/-//g;

	# pass to Date::Parse strptime
	my @time = strptime($datestring);

	# use Time::DayOfYear ymd2doy to find day of year
	my $doy = ymd2doy($time[3],$time[4]+1,$time[5]);

	# convert to form YYYY:DOY
	$datestring = $time[3] . ":" . $doy;

    }
    else{
	    return "DateError";
    }

    $datestring = $datestring . ":00:00:00.00";
    my $JD0 = 2450814.0;	# Julian date at CXC time=0.0
    my $time_seconds = Ska::Convert::date2time($datestring);
    my $jd = $JD0 + $time_seconds/86400;
    return $jd;

}

##**************************************************************************
sub printList{
##**************************************************************************
# Perform basic input checking
# Return an error html page or run the printAttitudes sub to
# print the OR List or Attitude List

    my($date,$type) = @_;

    print header(),   start_html('Dark Cal Attitudes');
    
    my $time = shortJulianDate($date);

    if ($time eq "DateError"){
	print "<pre> \n";

	print "Date Error:  Could not parse date. \n";
	print "Go Back and try again with date in form \n";
	print "YYYY:DOY or YYYY-MMM-DD \n";
	print "</pre> \n";
	print end_html();

    }
    elsif (($z_low_limit !~ /^(\d+\.?\d*|\.\d+)$/) || ($z_up_limit !~ /^(\d+\.?\d*|\.\d+)$/)){
	print "<pre> \n";
	print "Limit Error: Limits must be numeric. \n";
	print "Go Back and try again. \n";
	print "<pre> \n";
	print end_html();
    }
    elsif ($z_up_limit < $z_low_limit){
	print "<pre> \n";
	print "Upper Limit less than Lower Limit! \n";
	print "Go Back and try again. \n";
	print "<pre> \n";
	print end_html();
    }
    else{

    	our @table  = loadTable();
    
	(my $ra, my $dec) = sun_ra_dec($time);
	(my $el, my $eb) = ra_dec_el_eb($ra, $dec);

	readAttitudes();
	addZodi($el);
	@attitudes = zodiSort();

	printAttitudes($date,$time,$ra,$dec,$el,$eb,$type);
	
	print end_html();
   }	
}



sub addZodi{
    my($sun_el) = @_;	


# loop through the available attitudes
    for( my $j = 0; $j < scalar(@attitudes); $j++){

	my $pos_el = $attitudes[$j]{ec_el};
	my $pos_ra = $attitudes[$j]{eq_ra};
	my $pos_dec = $attitudes[$j]{eq_dec};
	my $n9_0 = $attitudes[$j]{n9_0};
	my $n10_3 = $attitudes[$j]{n10_3};
	my $n11_5 = $attitudes[$j]{n11_5};

# find L - Lsolar

	my $dll= abs($sun_el-$pos_el);
	if ($dll > 180){
		$dll = 360-$dll;
	}
	my $pos_eb = $attitudes[$j]{ec_eb};
	my $deb = abs($pos_eb);


	if ($deb > 180){
		$deb = 360 - $deb;
	}

# get a value for zodiacal light at particular attitude
# if value falls between limits, print the coordinates

	my $zodi = calcZodi($dll,$deb);

# Add the zodi information to the attitude array/hash
	$attitudes[$j]{zodi} = $zodi;

	}
}	

sub zodiSort{

my @satts = sort { $a -> {n9_0} <=> $b -> {n9_0} || $a-> {zodi} <=> $b->{zodi}  } @attitudes;

return @satts;


}

# CODE HERE

=head1 NAME

attitude.pl - CGI Perl script to choose Dark Current Calibration Attitudes

=head1 SYNOPSIS

attitude.pl [options]

=head1 OPTIONS

=over 8

=back

=head1 DESCRIPTION

B<attitude.pl> 

	CGI Perl script that takes in parameters (from an  
	external html form) for date, type (OR List or ATT List), and 
	limits on zodiacal light brightness, and returns a Pseudo-OR 
	list or a list of attitudes.  If given no parameters, the empty 
	form is returned.

	Both return types display the list of attitudes in sorted order 
	first by the number of 9.0 magnitude or greater stars then by the 
	zodiacal brightness.

	Zodiacal brightness is calculated using a table of zodiacal 
	brightness values based on table 17 of 
	Leinert et al. (1998), A&AS, 127, 1 .
	
	The list of attitudes (returned from the "ATT List" menu choice) 
	shows the complete list of potential dark current calibration 
	attitudes.  Those with zodiacal brightness outside the limits 
	specified by the input form have that zodiacal brightness 
	printed in red.

	The Pseudo-OR list is designed to be used with flight tools.  
	Attitudes that have zodiacal brightness outside the specified 
	limits are not included in this format list.
	Note that the IDs are just consecutive.


=head2 EXAMPLE

Parameters may be inserted at the command line for testing:
 	

	attitude.pl date="2005:191" type="ATT List" z_low="0" z_up="250"

=head1 AUTHOR

Jean Connelly (jconnelly@cfa.harvard.edu)
