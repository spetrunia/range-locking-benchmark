#!/bin/bash

SERVERNAME=$1
RUN_NAME=$2

USAGE_STR="Usage: $0 server_name test_run_name"

if [ "x${SERVERNAME}y" = "xy" ] ; then
  echo $USAGE_STR
  exit 1
fi

if [ "x${RUN_NAME}y" = "xy" ] ; then
  echo $USAGE_STR
  exit 1
fi

SERVER_DIR=mysql-5.6-$SERVERNAME
if [ ! -d $SERVER_DIR ]; then 
  echo "Bad server name $SERVERNAME."
  exit 1
fi

RESULT_DIR=results/$RUN_NAME

if [ -d $RESULT_DIR ]; then
  echo "Result directory for $RUN_NAME already exists"
  exit 1
fi

echo "Starting test "$RUN_NAME" with $SERVER_DIR"

killall -9 mysqld
sleep 5

DATA_DIR=data-fbmysql-$SERVERNAME
rm -rf $DATA_DIR
cp -r ${DATA_DIR}.clean $DATA_DIR

./$SERVER_DIR/sql/mysqld --defaults-file=./my-fbmysql-${SERVERNAME}.cnf & 

attempts=0

while true ; do
  ./$SERVER_DIR/client/mysql --defaults-file=./my-fbmysql-${SERVERNAME}.cnf -uroot -e "create database sbtest"

  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1

  attempts=$((attempts + 1))
  if [ $attempts -ge 10 ]; then 
    echo "Failed!"
    exit 1
  fi 
done


RESULT_DIR=results/$RUN_NAME

mkdir -p $RESULT_DIR

SYSBENCH_ARGS=" --db-driver=mysql --mysql-host=127.0.0.1 --mysql-user=root \
  --mysql-storage-engine=rocksdb \
  --time=60 \
  /usr/share/sysbench/oltp_read_write.lua --table-size=1000000"
SYSBENCH_TEST="oltp_read_write.lua"

cat > $RESULT_DIR/info.txt <<END
SERVERNAME=$SERVERNAME
SYSBENCH_TEST=$SYSBENCH_TEST
SERVER_DIR=$SERVER_DIR
SYSBENCH_ARGS=$SYSBENCH_ARGS

END

sysbench $SYSBENCH_ARGS prepare | tee $RESULT_DIR/sysbench-prepare.txt

./$SERVER_DIR/client/mysql --defaults-file=./my-fbmysql-${SERVERNAME}.cnf \
  -uroot -e "show variables like 'rocksdb%'" > $RESULT_DIR/variables-rocksdb.txt

./$SERVER_DIR/client/mysql --defaults-file=./my-fbmysql-${SERVERNAME}.cnf \
  -uroot -e "show variables" > $RESULT_DIR/variables-all.txt

./$SERVER_DIR/client/mysql --defaults-file=./my-fbmysql-${SERVERNAME}.cnf \
  -uroot -e "select * from information_schema.GLOBAL_STATUS where variable_name like 'ROCKSDB%'" > $RESULT_DIR/status-before-test.txt

./$SERVER_DIR/client/mysql --defaults-file=./my-fbmysql-${SERVERNAME}.cnf \
  -uroot -e "create table test.rocksdb_vars as select * from information_schema.GLOBAL_STATUS where variable_name like 'ROCKSDB%'"


for threads in 1 5 10 20 40 ; do
  #echo "THREADS $threads $storage_engine"


  SYSBENCH_ALL_ARGS="$SYSBENCH_ARGS --threads=$threads"

  OUTFILE="${RESULT_DIR}/sysbench-run-${threads}.txt"
  sysbench $SYSBENCH_ALL_ARGS run | tee $OUTFILE
done

./$SERVER_DIR/client/mysql --defaults-file=./my-fbmysql-${SERVERNAME}.cnf \
  -uroot \
  -e "select A.VARIABLE_NAME, B.VARIABLE_VALUE - A.VARIABLE_VALUE \
      from information_schema.GLOBAL_STATUS B, test.rocksdb_vars A \
      where B.VARIABLE_NAME=A.VARIABLE_NAME AND B.VARIABLE_VALUE - A.VARIABLE_VALUE >0" > $RESULT_DIR/status-after-test.txt



