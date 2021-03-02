#!/bin/bash

./setup-server/setup-fbmysql8-clone.sh range-locking fb-mysql-8.0.17-range-locking-jan21
./setup-server/setup-fbmysql8-clone.sh orig          fb-mysql-8.0.17-range-locking-jan21-base

echo "rocksdb_use_range_locking=1" >>  my-fbmysql-range-locking.cnf

