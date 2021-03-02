#!/bin/bash

set -e

# Usage: name [revno]
name=$1
branch=$2
revno=$3

if [ "x${name}y" = "xy" ] ; then
  echo "usage: $0 name branch [revno]"
fi

if [ "x${branch}y" = "xy" ] ; then
  echo "usage: $0 name branch [revno]"
fi

DATADIR=`pwd`/data-fbmysql-$name
DIRNAME=mysql-8.0-$name
BASEDIR=`pwd`/$DIRNAME

git clone --branch $branch --single-branch https://github.com/spetrunia/mysql-5.6.git $DIRNAME
cd $DIRNAME

if [ "x${revno}y" != "xy" ] ; then
  git reset --hard $revno
fi

git submodule init
git submodule update
mkdir -p build
cd build

cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DDOWNLOAD_BOOST=1 \
  -DWITH_BOOST=/home/ubuntu/mysql-8.0-boost \
  -DCMAKE_CXX_FLAGS="-march=native" \
  -DENABLE_DOWNLOADS=1 \
  -DWITH_UNIT_TESTS:BOOL=OFF \
  -DWITH_SSL:STRING=system -DWITH_ZLIB:STRING=system \
  -DWITH_ZSTD:STRING=/usr/local -DWITH_LZ4:STRING=system \

make -j20
cd ../..

cat > my-fbmysql-$name.cnf << EOF
[client]
socket=/tmp/mysql.sock

[mysqld]

datadir=$DATADIR
default-storage-engine=rocksdb

rocksdb
rocksdb_perf_context_level=2
# rocksdb_use_range_locking=1 

#debug
# log-bin=pslp
binlog-format=row

tmpdir=/tmp
port=3306
socket=/tmp/mysql.sock
gdb

log-error
lc_messages_dir=$BASEDIR/build/share
lc_messages=en_US
server-id=12

EOF

echo "Run $BASEDIR/build/bin/mysqld --defaults-file=`pwd`/my-fbmysql-$name.cnf --initialize-insecure"

