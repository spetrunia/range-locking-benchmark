#!/bin/bash

#./setup-fbmysql8.sh

RESULT=55-nosk-perf
#./run-test.sh -e -m orig          51-nosk-orig
./run-test.sh -e -m -p range-locking $RESULT

#./summarize-result.sh 51-nosk-orig
./summarize-result.sh $RESULT

