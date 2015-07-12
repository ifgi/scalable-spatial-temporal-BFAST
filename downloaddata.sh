#!/bin/bash
echo "##################################################"
echo "DOWNLOAD DATA"
echo "##################################################"

OUT_FOLDER=/home/scidb
BASE_URL=http://e4ftl01.cr.usgs.gov/MOLT
PRODUCT=MOD09Q1
COLLECTION=005
TILE_FILTER=h12v10
FILE_FILTER=A20[0-1][0-9][0-3][0-9][0-9]
YEAR_START=2000
YEAR_END=2001
#RANGE_MONTHS={0..1}{0..9}
RANGE_MONTHS=0{1..3}
RANGE_DAYS={0..3}{0..9}
TEST=--dry-run

parallel -j 8 --no-notice $TEST wget -r -np --retry-connrefused --wait=1 --directory-prefix $OUT_FOLDER --accept  $PRODUCT.$FILE_FILTER.$TILE_FILTER* $BASE_URL/$PRODUCT.$COLLECTION/{1}.$RANGE_MONTHS.$RANGE_DAYS/ ::: {$YEAR_START..$YEAR_END}
