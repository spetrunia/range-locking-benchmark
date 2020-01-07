#!/bin/bash

#./setup.sh

echo "rocksdb_use_range_locking=1" >>  my-fbmysql-range-locking.cnf

./run-test.sh -m orig 01-orig
./run-test.sh -m range-locking 02-range-locking

./summarize-result.sh 01-orig
./summarize-result.sh 02-range-locking

