#!/bin/bash


./setup-server/setup-fbmysql-clone.sh range-locking range-locking-fb-mysql-5.6.35
./setup-server/setup-fbmysql-clone.sh orig          range-locking-fb-mysql-5.6.35-orig

cp -r data-fbmysql-orig data-fbmysql-orig.clean
cp -r data-fbmysql-range-locking data-fbmysql-range-locking.clean

