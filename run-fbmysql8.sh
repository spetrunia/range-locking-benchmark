#!/bin/bash

#./setup-fbmysql8.sh

./run-test.sh -m orig 01-orig
./run-test.sh -m range-locking 02-range-locking

./summarize-result.sh 01-orig
./summarize-result.sh 02-range-locking

