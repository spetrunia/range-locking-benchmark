#!/bin/bash


./setup-server/setup-fbmysql-clone.sh range-locking fb-mysql-8.0.17-range-locking-jan21
./setup-server/setup-fbmysql-clone.sh orig          fb-mysql-8.0.17-range-locking-jan21-base

cp -r data-fbmysql-orig data-fbmysql-orig.clean
cp -r data-fbmysql-range-locking data-fbmysql-range-locking.clean

