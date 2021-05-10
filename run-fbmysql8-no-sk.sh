#!/bin/bash

#./setup-fbmysql8.sh

./run-test.sh -e -m orig 20-nosk-orig
./run-test.sh -e -m range-locking 21-nosk-range-locking

./summarize-result.sh 20-nosk-orig
./summarize-result.sh 21-nosk-range-locking

