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
BASEDIR=`pwd`/mysql-5.6-name

#git clone --branch $branch --depth 1 https://github.com/spetrunia/mysql-5.6.git mysql-5.6-$name
git clone --branch $branch --single-branch https://github.com/spetrunia/mysql-5.6.git mysql-5.6-$name
cd mysql-5.6-$name

if [ "x${revno}y" != "xy" ] ; then
  git reset --hard $revno
fi

git submodule init
git submodule update
cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_SSL=system \
  -DWITH_ZLIB=bundled -DMYSQL_MAINTAINER_MODE=0 -DENABLED_LOCAL_INFILE=1 \
  -DENABLE_DTRACE=0 -DCMAKE_CXX_FLAGS="-march=native"
make -j8

cd mysql-test
./mtr alias
cp -r var/install.db $DATADIR
cd ../..

cat > my-fbmysql-$name.cnf << EOF
[mysqld]

datadir=$DATADIR

default-storage-engine=rocksdb
skip-innodb
default-tmp-storage-engine=MyISAM
rocksdb

#debug
log-bin=pslp
binlog-format=row

tmpdir=/tmp
port=3306
socket=/tmp/mysql.sock
gdb

language=$BASEDIR/share/english
server-id=12

# rocksdb_use_range_locking=1 
EOF

echo "$BASEDIR/sql/mysqld --defaults-file=`pwd`/my-fbmysql-$name.cnf"

#(cd ./mysql-5.6/sql; ./mysqld --defaults-file=../../my-fbmysql.cnf & )

