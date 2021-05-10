#!/bin/bash

#./setup-fbmysql8.sh

./run-test.sh -c -e -m orig 30-4cfnosk-orig
./run-test.sh -c -e -m range-locking 31-4cfnosk-range-locking

./summarize-result.sh 30-4cfnosk-orig
./summarize-result.sh 31-4cfnosk-range-locking

