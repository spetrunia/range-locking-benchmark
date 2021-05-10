#!/bin/bash

#./setup-fbmysql8.sh

#./run-test.sh -m orig 01-orig
./run-test.sh -m range-locking 40-range-as-point

#./summarize-result.sh 01-orig
./summarize-result.sh 40-range-as-point

