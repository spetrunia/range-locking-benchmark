#!/bin/bash

./setup.sh

echo "rocksdb_use_range_locking=1" >>  my-fbmysql-range-locking.cnf

./run-test.sh orig 01-orig
./run-test.sh range-locking 02-range-locking

