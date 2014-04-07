#! /bin/csh -x
# SGE commands
#$ -cwd
#$ -j y
#$ -S /bin/csh
#$ -m abe
#$ -M ishu@hydro.washington.edu
#$ -N soil_type_colum
#$ -q default.q@compute-0-0.local
### This script crop the original 30s soil type file to 0.0625 netcdf file for CRB
set BASEDIR = "/raid3/ishu/BPA/"
set INDIR = "$BASEDIR/parameter_files/"
set tool_dir = "$BASEDIR/tools/"
set PNW_PARAM_FILE = "/raid9/ishu/integrated_scenario/parameter_files"
set XYZZ_asc_int = "$tool_dir/quick_arc_info_from_lat_lon_int_val.pl"
set XYZZ_asc = "$tool_dir/quick_arc_info_from_lat_lon_val.pl"
set Resolution = "0.0625"
# create soil_type for CRB from PNW PARAMETER
set VAR = "soil_type"
echo "Creating $VAR for CRB"
set OUTDIR = "$INDIR/CRB_PARMS/"$VAR""
mkdir -p $OUTDIR
set OUT_XYZZ = "$OUTDIR/"$VAR"_0.0625_CRB.xyzz"
set OUT_ASC = "$OUTDIR/"$VAR"_0.0625_CRB.asc"
awk 'NR==FNR{a[$1,$2]++;next} (a[$1,$2])' $BASEDIR/data/colum_0.0625/forcing/grid_info/match_flowd_2860_bena_all_v.1.1_reverse $PNW_PARAM_FILE/"$VAR"/"$VAR"_0.0625_PNW_interpolate.xyzz_matched  > $OUT_XYZZ
$XYZZ_asc_int $OUT_XYZZ $Resolution $OUT_ASC

# create veg_type for CRB from PNW PARAMETER
set VAR = "veg_type"
echo "Creating $VAR for CRB"
set OUTDIR = "$INDIR/CRB_PARMS/"$VAR""
mkdir -p $OUTDIR
set OUT_XYZZ = "$OUTDIR/"$VAR"_0.0625_CRB.xyzz"
set OUT_ASC = "$OUTDIR/"$VAR"_0.0625_CRB.asc"
awk 'NR==FNR{a[$1,$2]++;next} (a[$1,$2])' $BASEDIR/data/colum_0.0625/forcing/grid_info/match_flowd_2860_bena_all_v.1.1_reverse $PNW_PARAM_FILE/"$VAR"/"$VAR"_0.0625_PNW_interpolate.xyzz_matched  > $OUT_XYZZ
$XYZZ_asc_int $OUT_XYZZ $Resolution $OUT_ASC

# create albedo for CRB from PNW PARAMETER
set VAR = "albedo"
echo "Creating $VAR for CRB"
set OUTDIR = "$INDIR/CRB_PARMS/"$VAR""
mkdir -p $OUTDIR
set OUT_XYZZ = "$OUTDIR/"$VAR"_0.0625_CRB.xyzz"
set OUT_ASC = "$OUTDIR/"$VAR"_0.0625_CRB.asc"
awk 'NR==FNR{a[$1,$2]++;next} (a[$1,$2])' $BASEDIR/data/colum_0.0625/forcing/grid_info/match_flowd_2860_bena_all_v.1.1_reverse $PNW_PARAM_FILE/"$VAR"/"$VAR"_0.0625_PNW_interpolate.xyzz_matched  > $OUT_XYZZ
$XYZZ_asc_int $OUT_XYZZ $Resolution $OUT_ASC

