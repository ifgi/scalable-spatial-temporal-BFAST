#!/bin/bash

ARRAY_NAME=MOD09Q1

NVERSION=$(iquery -aq "versions($ARRAY_NAME);" | wc -l)
let NVERSION=$(($NVERSION - 2))
IQUERYCMD="iquery -aq \"remove_versions($ARRAY_NAME, $NVERSION);\""
eval $IQUERYCMD
