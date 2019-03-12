#!/bin/bash

RUN_NAME=$1

USAGE_STR="Usage: $0 test_run_name"
if [ "x${RUN_NAME}y" = "xy" ] ; then
  echo $USAGE_STR
  exit 1
fi

# The parameter of this script can be either path to results directory
# or just a name in the result.

if [[ -d $RUN_NAME ]] ; then
  RESULT_DIR=$RUN_NAME
else
  RESULT_DIR=results/$RUN_NAME
fi

if [ ! -d $RESULT_DIR ]; then
  echo "Result directory for $RUN_NAME doesn't exist"
  exit 1
fi

SERVER_DIR=`grep SERVER_DIR $RESULT_DIR/info.txt`
SYSBENCH_TEST=`grep SYSBENCH_TEST $RESULT_DIR/info.txt`

echo $SERVER_DIR
echo $SYSBENCH_TEST

#################################################################

printf "Threads,\tQPS\n"

for i in $RESULT_DIR/sysbench-run-?.txt ; do 
  if [[ -f $i ]]; then
    THR=`perl -ne 'print $1 if ( /Number of threads: ([0-9]+)/)' $i`
    QPS=`perl -ne 'print $1 if ( /queries: *[0-9]+ +\(([0-9.]+) per sec\.\)/)' $i`
    printf "%s\t%s\n" $THR $QPS
  fi
done

for i in $RESULT_DIR/sysbench-run-??.txt ; do 
  if [[ -f $i ]]; then
    THR=`perl -ne 'print $1 if ( /Number of threads: ([0-9]+)/)' $i`
    QPS=`perl -ne 'print $1 if ( /queries: *[0-9]+ +\(([0-9.]+) per sec\.\)/)' $i`
    #echo "$THR, $QPS"
    printf "%s\t%s\n" $THR $QPS
  fi
done

for i in $RESULT_DIR/sysbench-run-???.txt ; do 
  if [[ -f $i ]]; then
    THR=`perl -ne 'print $1 if ( /Number of threads: ([0-9]+)/)' $i`
    QPS=`perl -ne 'print $1 if ( /queries: *[0-9]+ +\(([0-9.]+) per sec\.\)/)' $i`
    printf "%s\t%s\n" $THR $QPS
  fi
done

