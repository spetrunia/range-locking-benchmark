#!/bin/bash

#./setup-fbmysql8.sh

./run-test.sh -c -m orig 10-4cf-orig
./run-test.sh -c -m range-locking 11-4cf-range-locking

./summarize-result.sh 10-4cf-orig
./summarize-result.sh 11-4cf-range-locking

