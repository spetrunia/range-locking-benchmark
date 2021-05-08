#!/bin/bash

./setup-server/setup-fbmysql8-clone.sh range-locking fb-mysql-8.0.20-range-locking-mar
./setup-server/setup-fbmysql8-clone.sh orig          fb-mysql-8.0.20-range-locking-mar-base

echo "rocksdb_use_range_locking=1" >>  my-fbmysql-range-locking.cnf

