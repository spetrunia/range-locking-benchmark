set -e

# Usage: name [revno]
name=$1
branch=$2
revno=$3

if [ "x${name}y" = "xy" ] ; then
  echo "usage: $0 name branch [revno]"
fi

# range-locking-fb-mysql-5.6.35
if [ "x${branch}y" = "xy" ] ; then
  echo "usage: $0 name branch [revno]"
fi

DATADIR=`pwd`/data-fbmysql-$name
BASEDIR=`pwd`/mysql-5.6-$name

#git clone --branch $branch --depth 1 https://github.com/spetrunia/mysql-5.6.git mysql-5.6-$name
git clone --branch $branch --single-branch https://github.com/spetrunia/mysql-5.6.git mysql-5.6-$name
cd mysql-5.6-$name

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
  -DWITH_SSL:STRING=system -DWITH_ZLIB:STRING=system \
  -DWITH_ZSTD:STRING=/usr/local -DWITH_LZ4:STRING=system \

make -j20
cd ..

cd mysql-test
../build/mysql-test/mtr alias
cp -r ../build/mysql-test/var/data $DATADIR
cp -r ../build/mysql-test/var/data $DATADIR.clean
cd ../..

cat > my-fbmysql-$name.cnf << EOF
[client]
socket=/tmp/mysql.sock

[mysqld]

datadir=$DATADIR

default-storage-engine=rocksdb
skip-innodb
default-tmp-storage-engine=MyISAM
rocksdb

#debug
# log-bin=pslp
binlog-format=row

tmpdir=/tmp
port=3306
socket=/tmp/mysql.sock
gdb

log-error
language=$BASEDIR/sql/share/english
server-id=12

rocksdb_perf_context_level=2
# rocksdb_use_range_locking=1 

EOF

echo "$BASEDIR/sql/mysqld --defaults-file=`pwd`/my-fbmysql-$name.cnf"

#(cd ./mysql-5.6/sql; ./mysqld --defaults-file=../../my-fbmysql.cnf & )

