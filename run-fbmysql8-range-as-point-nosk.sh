#!/bin/bash

#./setup-fbmysql8.sh

#./run-test.sh -m orig 01-orig
./run-test.sh -e -m range-locking 42-range-as-point-nosk

#./summarize-result.sh 01-orig
./summarize-result.sh 42-range-as-point-nosk

