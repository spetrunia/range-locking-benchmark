#!/bin/bash

#./setup-fbmysql8.sh

RESULT=56-perf
#./run-test.sh -e -m orig          51-nosk-orig
./run-test.sh -m -p range-locking $RESULT

#./summarize-result.sh 51-nosk-orig
./summarize-result.sh $RESULT

