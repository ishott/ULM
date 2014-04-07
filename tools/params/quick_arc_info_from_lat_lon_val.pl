#!/usr/bin/perl

## Creat an arc-info style data file from a lat-lon-value list
##  Inputs are lat-lon-value list, resolution, and outfile name
## AUTHOR: B.LIVNEH
#
#
# Example
# quick_arc_info_from_list.pl /raid/blivneh/conus/swe_sm_tests/coords/total.list 0.5 /raid/blivneh/conus/swe_sm_tests/coords/total.asc 1 /raid/blivneh/conus/swe_sm_tests/vic_R2_EXPS.asc
#
#

$lat_lon_list = shift;
$res = shift;
$outfile = shift;
$altflag = shift;
$altlist = shift; # optional lat lon list for a differnt domain than lat-lon window
$no_data = -99.00;
$data = 1;

## Compute min and max, lat and lon from LAT_LON_LIST soil file, then make horizontal
## passes from NW to SE and create a mask
$min_lat = 90;
$max_lat = -90;
$min_lon = 180;
$max_lon = -180;
$n_cols = 0;
$nrows = 0;
$cell_found = 0;

if ($altflag == 1) {
  $list = "$altlist";
}
else {
  $list = "$lat_lon_list";
}
open(LAT_LON0, $list);
foreach $line0 (<LAT_LON0>) {
  chomp $line0;
  $line0 =~ s/^\s+//;
  @column0 = split /\s+/, $line0;
  if ($column0[0] < $min_lat) {
    $min_lat = $column0[0];
  }
  if ($column0[0] > $max_lat) {
    $max_lat = $column0[0];
  }
  if ($column0[1] < $min_lon) {
    $min_lon = $column0[1];
  }
  if ($column0[1] > $max_lon) {
    $max_lon = $column0[1];
  }
}
close(LAT_LON0);


$ncols = ($max_lon - $min_lon)/$res + 1;
$nrows = ($max_lat - $min_lat)/$res + 1;
$xllcorner = $min_lon - $res*0.5;
$yllcorner = $min_lat - $res*0.5;


## Index lat and lon so that only one loop will be required 
@lat_lon_index = ();

## First initialize this array to no_data values

for($x=0;$x<=(($max_lat-$min_lat)/$res);$x++) {
  for($y=0;$y<=(($max_lon-$min_lon)/$res);$y++) {
    $lat_lon_index[$x][$y] = $no_data;
  }
}

## Now pass through the file and assign each point to the coresponding array element

open(LAT_LON2, $lat_lon_list);
foreach $line2 (<LAT_LON2>) {
  chomp $line2;
  $line2 =~ s/^\s+//;
  @column2 = split /\s+/, $line2;
  $lat_lon_index[(($column2[0]-$min_lat)/$res)][(($column2[1]-$min_lon)/$res)] = $column2[2];
}
close(LAT_LON2);

#print output
open(OUTFILE, ">$outfile");
printf OUTFILE "ncols           $ncols\n";
printf OUTFILE "nrows          $nrows\n";
printf OUTFILE "xllcorner       %.5f\n",$xllcorner;
printf OUTFILE "yllcorner       %.5f\n",$yllcorner;
printf OUTFILE "cellsize        $res\n";
printf OUTFILE "NODATA_value    $no_data\n";

$lat = 0;
$lon = 0;
for ($i = 0; $i < $nrows; $i++) {
  for ($j = 0; $j < $ncols; $j++) {
    $lat = $max_lat - $i*$res;
    $lon = $min_lon + $j*$res;
#    print "test $lat_lon_index[(($lat-$min_lat)/$res)][(($lon-$min_lon)/$res)]\n";
    if ($lat_lon_index[(($lat-$min_lat)/$res)][(($lon-$min_lon)/$res)] != $no_data) {
      printf OUTFILE "%f\t", $lat_lon_index[(($lat-$min_lat)/$res)][(($lon-$min_lon)/$res)];
	}
    else {
      printf OUTFILE "%.1f ", $no_data;
    }
    if ($j == ($ncols - 1)) {
      #printf OUTFILE "\n" unless ($i == ($nrows - 1));
      printf OUTFILE "\n";
    }
  }
} 
#printf STDOUT "%.4f %.4f %.4f %.4f \n", $min_lat, $max_lat, $min_lon, $max_lon;
