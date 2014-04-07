#!/usr/bin/perl
# This script will derive a complete set of SAC parameters from only
# soil texture and dominant vegetation class information following
# the techniques proposed by Koren et al., 2003.
# peadj and pescale files NOT created
#
# derive_sac_parameters.pl /raid/blivneh/mopex/All_CONUS_Basins/carna_data/noah_params/soil_0.125.carna.asc 400 2000 /raid/blivneh/mopex/All_CONUS_Basins/carna_data/sac_apriori_params

$soilfile = shift;
$Zup = shift; #Upper zone depth (mm)
$Zmax = shift; #Total zone (upper + lower) depth (mm)
$outdir = shift; #directory where output files will go

print "soilfile $soilfile\n";

unless (-e $outdir) {
  $cmd = "mkdir $outdir";
  print "$cmd\n";
  system($cmd);
}

# Based on 12 STATSGO (Miller & White, 1999) soil classe; classes above 12 were manually added for ameriflux sites
# 3-Blodgett, 9-Brookings, 4-Howland, 6-Niwot
@sand = (0.92,0.82,0.58,0.17,0.09,0.43,0.58,0.10,0.32,0.52,0.06,0.22);
@clay = (0.03,0.06,0.10,0.13,0.05,0.18,0.27,0.34,0.34,0.42,0.47,0.58);
@psi_fld = (10,10,10,20,20,20,20,20,20,20,20,20);
# From Noah tables -- units: m/s, converted in lzpk equation to mm/s
@Ksat = (1.7600E-4,1.4078E-5,5.2304E-6,2.8089E-6,2.8089E-6,3.3770E-6,4.4518E-6,2.0348E-6,2.4464E-6, 7.2199E-6,1.3444E-6,9.7394E-7);

$psi_wlt = 1500;  # Koren et al., 2003
$n1 = 1.6; #Koren et al., 2000
$Ds = 0.0000025; #Native units are 1/km, convert to mm
$Beta = 16; #Koren derived
$deltaT = 86400; #SAC day time step converted to seconds
$s_wlt_sand = 0.04; 
$pi = 3.14159;

# List of parameters -- order is important
@params = ("uztwm","uzfwm","uzk","lztwm","lzfsm","lzfpm","lzsk","lzpk","pfree","zperc","rexp");

# Read in soil and veg files into arrays

open (SOIL,$soilfile) or die "$0: ERROR: cannot open basin $soilfile\n";
$row = 0;
foreach (<SOIL>) {
  chomp;
  if (/^\s*NCOLS\s+(\S+)/i) {
    $ncols_soil = $1;
  }
  elsif (/^\s*NROWS\s+(\S+)/i) {
    $nrows_soil = $1;
  }
  elsif (/^\s*XLLCORNER\s+(\S+)/i) {
    $xllcorner_soil = $1;
  }
  elsif (/^\s*YLLCORNER\s+(\S+)/i) {
    $yllcorner_soil = $1;
  }
  elsif (/^\s*cellsize\s+(\S+)/i) {
    $cellsize_soil = $1;
  }
  elsif (/^\s*NODATA.*\s+(\S+)/i) {
    $nodata_soil = $1;
  }
  else {
    s/^\s+//;
    @fields = split /\s+/;
    if (@fields) {
      for ($col=0; $col<$ncols_soil; $col++) {
	# row index should be nrows_soil-row-1, due to top row occurring first in asc file
	$soil[$nrows_soil-$row-1][$col] = $fields[$col];
      }
      $row++;
    }
  }
}
close (SOIL);

# Loop through arrays and compute SAC params
$count = 0;
for ($i = 0; $i <= $#soil; $i++) {
  for ($j = 0; $j <= $#{$soil[$i]}; $j++) {
    if ($soil[$i][$j] != $nodata_soil) {
      #print "soil type $soil[$i][$j]  ";
      $stxt = $soil[$i][$j] - 1;  #soil type (since arrays start at '0', need stxt + 1)
      if ($stxt>$#sand) {
	print "\n\nsoil type $soil[$i][$j] exceeds maximum $#sand+1, setting to max value\n\n";
	$stxt = $#sand;
      }
      #Hydraulic properties via regressoin equations (Cosby et al., 1984)
      $s_max = -0.126 * $sand[$stxt] + 0.489;  #porosity, or saturation point
      #print "smax $s_max\n";
      $psi_sat = 7.74 * exp(-3.02 * $sand[$stxt]); #saturation matrix potential
      #printf STDOUT "%d %s   %.8f\n",$soil[$i][$j],"psisat",$psi_sat;
      $brt = 15.9 * $clay[$stxt] + 2.91; #slope of retention curve (Campbell, 1974)
      #printf STDOUT "%d %s   %.8f\n",$soil[$i][$j],"brt",$brt;
      $quartz = $sand[$stxt]; #quartz content
      #print "quartz $quartz\n";
      $s_fld = $s_max * ($psi_fld[$stxt] / $psi_sat)**(-1 / $brt); #field capacity
      #printf STDOUT "%d %s   %.8f\n",$soil[$i][$j],"sfld",$s_fld;
      $s_wlt = $s_max * ($psi_wlt / $psi_sat)**(-1 / $brt); #wilting point
      #printf STDOUT "%d %s   %.8f\n",$soil[$i][$j],"swlt",$s_wlt;
      $mu = 3.5 * (($s_max - $s_fld)**1.66); #specific yield (Armstrong, 1978)
      #printf STDOUT "%d %s   %.8f\n",$soil[$i][$j],"mu",$mu;
      #printf STDOUT "%.6f %.6f\n",($s_max-$s_fld),(($s_max-$s_fld)**1.66);
      $s_crit = $s_wlt + ($s_fld - $s_wlt)/3;
      #printf STDOUT "%s %d  SMAX %.6f  SFLD %.6f  SWLT %.6f  CRIT1 %.6f CRIT1 %.6f\n", "TOTAL", $soil[$i][$j],$s_max, $s_fld, $s_wlt,(0.7*$s_fld),$s_crit;
      #SAC parameters
      $uztwm[$i][$j] = ($s_fld - $s_wlt) * $Zup;
      #print "uztwm $uztwm[$i][$j]\n";
      $uzfwm[$i][$j] = ($s_max - $s_fld) * $Zup;
      #print "uzfwm $uzfwm[$i][$j]\n";
      $uzk[$i][$j] = 1 - ($s_fld / $s_max)**$n1;
      #print "uzk $uzk[$i][$j]\n";
      $lztwm[$i][$j] = ($s_fld - $s_wlt) * ($Zmax - $Zup);
      #print "lztwm $lztwm[$i][$j]\n";
      $lzfsm[$i][$j] = ($s_max - $s_fld) * ($Zmax - $Zup) * ($s_wlt / $s_max)**$n1;
      #print "lfswm $lzfsm[$i][$j]\n";
      $lzfpm[$i][$j] = ($s_max - $s_fld) * ($Zmax - $Zup) * (1 - ($s_wlt / $s_max)**$n1);
      #print "lzfpm $lzfpm[$i][$j]\n";
      $lzsk[$i][$j] = ((1 - ($s_fld / $s_max)**$n1) / (1 + 2 * (1 - $s_wlt)));
      #print "lzsk $lzsk[$i][$j]\n";
      #printf STDOUT "%.4e %.4e %.4e %.4e %.4e %.4e\n",($pi**2),$Ksat[$stxt],($Ds**2),($Zmax-$Zup),$deltaT,$mu;
# units are important in lzpk: Eq'n A8 (Koren et al., 2003).  Ds is 1/km -- converted here to mm
# according to Youlong/Noah/MOPEX calibration, a 5.5 is needed on the Ksat value
      $lzpk[$i][$j] = 1 - exp(-(($pi**2)*$Ksat[$stxt]*1000*5.5*($Ds**2)*($Zmax-$Zup)*$deltaT)/$mu);
      #print "lzpk $lzpk[$i][$j]\n";
      $pfree[$i][$j] = ($s_wlt / $s_max)**$n1;
      #print "pfree $pfree[$i][$j]\n";
      $zperc[$i][$j] = (($lztwm[$i][$j]+$lzfsm[$i][$j]*(1-$lzsk[$i][$j])) + ($lzfpm[$i][$j]*(1-$lzpk[$i][$j]))) / ($lzfsm[$i][$j]*$lzsk[$i][$j]+$lzfpm[$i][$j]*$lzpk[$i][$j]);
      #print "zperc $zperc[$i][$j]\n";
      $rexp[$i][$j] = ($s_wlt / ($s_wlt_sand - 0.001))**0.5;
      #print "rexp $rexp[$i][$j]\n";
      print "ROW: $i COLUMN: $j SOIL $stxt \nuztwm $uztwm[$i][$j]\nuzfwm $uzfwm[$i][$j]\nuzk $uzk[$i][$j]\nlztwm $lztwm[$i][$j]\nlzfsm $lzfsm[$i][$j]\nlzfpm $lzfpm[$i][$j]\nlzsk $lzsk[$i][$j]\nlzpk $lzpk[$i][$j]\npfree $pfree[$i][$j]\nzprec $zperc[$i][$j]\nrexp $rexp[$i][$j]\n";
      print "\n\n\n COUNT = $count\n\n\n";
      $count++;
    }
  }
}

# Write output, assume all outputs are floating point numbers
for ($q=0;$q<=$#params;$q++) {
  $outfile = "$outdir/$params[$q].asc";
  open(OUTFILE,">$outfile") or die "cannot open $outfile";
  printf OUTFILE "NCOLS        %4d\n",$ncols_soil;
  printf OUTFILE "NROWS        %4d\n",$nrows_soil;
  printf OUTFILE "XLLCORNER    %9.5f\n",$xllcorner_soil;
  printf OUTFILE "YLLCORNER    %9.5f\n",$yllcorner_soil;
  printf OUTFILE "cellsize     %9.4f\n",$cellsize_soil;
  printf OUTFILE "NODATA_value %9.4f\n",$nodata_soil;
  for ($row=$nrows_soil-1; $row>=0; $row--) {
    for ($col=0; $col<$ncols_soil; $col++) {
      if ($soil[$row][$col] == $nodata_soil) {
	printf OUTFILE "%12.7f ", $soil[$row][$col];
      }
      else {
	printf OUTFILE "%12.7f ", ${"$params[$q]"}[$row][$col];
      }
    }
    print OUTFILE "\n";
  }
  close(OUTFILE);
}
