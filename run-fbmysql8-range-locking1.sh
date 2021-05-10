#!/bin/bash

#./setup-fbmysql8.sh

./run-test.sh -e -m orig          51-nosk-orig
./run-test.sh -e -m range-locking 52-nosk-range-locking-test1

./summarize-result.sh 51-nosk-orig
./summarize-result.sh 52-nosk-range-locking-test1

