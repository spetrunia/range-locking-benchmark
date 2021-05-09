usage () {
echo "Usage: $0 [-p] [-m] [-c] [-d] [-e] server_name test_run_name"
echo "  -p - Use perf for profiling"
echo "  -m - Put datadir on /dev/shm"
echo "  -c - Assume sysbench uses 4 tables and move them to different CFs."
echo "  -d - Same but use 2 CFs"
echo "  -e - Remove the secondary index"
}

###
### Parse options
###

while getopts ":pmcde" opt; do
  case ${opt} in
    p ) USE_PERF=1
      ;;
    m ) USE_RAMDISK=1
      ;;
    c ) USE_4_CFS=1
      ;;
    d ) USE_2_CFS=1
      ;;
    e ) DROP_SECONDARY_INDEX=1
      ;;
    \? ) 
	usage;
        exit 1
      ;;
  esac
done
shift $((OPTIND -1))

SERVERNAME=$1
RUN_NAME=$2

if [[ $USE_4_CFS && $USE_2_CFS ]] ; then
  echo "Use either -c (USE_4_CFS) or -d (USE_2_CFS)"
  exit 1
fi

if [ "x${SERVERNAME}y" = "xy" ] ; then
  usage;
  exit 1
fi

if [ "x${RUN_NAME}y" = "xy" ] ; then
  usage;
  exit 1
fi

I_S="information_schema"
SERVER_DIR=mysql-5.6-$SERVERNAME
if [ ! -d $SERVER_DIR ]; then 
  SERVER_DIR=mysql-8.0-$SERVERNAME
  USING_MYSQL8=1
  I_S="performance_schema"
  if [ ! -d $SERVER_DIR ]; then 
    SERVER_DIR=mysql-$SERVERNAME
    if [ ! -d $SERVER_DIR ]; then 
      echo "Bad server name $SERVERNAME."
      exit 1
    fi
  fi
fi

if [[ $USING_MYSQL8 ]]; then
  MYSQL_CLIENT=$SERVER_DIR/build/bin/mysql
  MYSQLD_BINARY=$SERVER_DIR/build/bin/mysqld
else
  MYSQL_CLIENT=$SERVER_DIR/client/mysql
  MYSQLD_BINARY=$SERVER_DIR/sql/mysqld 
fi

if [ ! -f $MYSQL_CLIENT ]; then
  echo "Cannot find $MYSQL_CLIENT"
  exit 1;
fi 

if [ ! -f $MYSQLD_BINARY ]; then
  echo "Cannot find $MYSQLD_BINARY"
  exit 1;
fi 


RESULT_DIR=results/$RUN_NAME

if [ -d $RESULT_DIR ]; then
  echo "Result directory for $RUN_NAME already exists"
  exit 1
fi


echo "Starting test "$RUN_NAME" with $SERVER_DIR"
if [[ $USE_PERF ]] ; then
  echo " Collecting perf profile"
fi

if [[ $USE_RAMDISK ]] ; then
  echo " Using /dev/shm for data dir"
fi

if [[ $USE_4_CFS ]] ; then
  echo " Data is in 4 tables"
fi

if [[ $USE_2_CFS ]] ; then
  echo " Data is in 2 tables"
fi

#############################################################################
### Start the server
killall -9 mysqld
sleep 5

DATA_DIR=data-fbmysql-$SERVERNAME
rm -rf $DATA_DIR

initialize_mysql8_datadir() {
  $MYSQLD_BINARY --defaults-file=./my-fbmysql-${SERVERNAME}.cnf --initialize-insecure
}

if [[ $USE_RAMDISK ]] ; then
  rm -rf /dev/shm/$DATA_DIR
  rm -rf /dev/shm/data-fbmysql-*
  if [[ $USING_MYSQL8 ]] ; then
    # intialize 
    mkdir /dev/shm/$DATA_DIR
    ln -s /dev/shm/$DATA_DIR $DATA_DIR
    initialize_mysql8_datadir
  else
    cp -r ${DATA_DIR}.clean /dev/shm/$DATA_DIR
    ln -s /dev/shm/$DATA_DIR $DATA_DIR
  fi
else
  if [[ $USING_MYSQL8 ]] ; then
    mkdir $DATA_DIR
    initialize_mysql8_datadir
  else
    cp -r ${DATA_DIR}.clean $DATA_DIR
  fi
fi	

#exit 0;
MYSQL_CMD="$MYSQL_CLIENT --defaults-file=./my-fbmysql-${SERVERNAME}.cnf -uroot"

server_attempts=0

while true ; do
  $MYSQLD_BINARY --defaults-file=./my-fbmysql-${SERVERNAME}.cnf & 
  sleep 5
  client_attempts=0
  while true ; do
    $MYSQL_CMD -e "drop database if exists sbtest"
    $MYSQL_CMD -e "create database sbtest"

    if [ $? -eq 0 ]; then
      break
    fi
    sleep 1

    client_attempts=$((client_attempts + 1))
    if [ $client_attempts -ge 10 ]; then 
      break;
    fi 
  done

  MYSQLD_PID=`ps -C mysqld --no-header | awk '{print $1}'`
  if [[ "a${MYSQLD_PID}b" != "ab" ]] ; then 
    break
  fi

  server_attempts=$((server_attempts + 1))
  if [ $server_attempts -ge 4 ]; then
    echo "Failed to launch mysqld"
    exit 1
  fi 
done

#############################################################################
### Prepare the benchmark

RESULT_DIR=results/$RUN_NAME

mkdir -p $RESULT_DIR

SYSBENCH_ARGS=" --db-driver=mysql --mysql-host=127.0.0.1 --mysql-user=root \
  --mysql-storage-engine=rocksdb \
  --time=60 \
  /usr/share/sysbench/oltp_write_only.lua" 

if [[ $USE_4_CFS ]] ; then
  SYSBENCH_ARGS="$SYSBENCH_ARGS	--tables=4 --table-size=250000"
elif [[ $USE_2_CFS ]] ; then 
  SYSBENCH_ARGS="$SYSBENCH_ARGS	--tables=2 --table-size=500000"
else
  SYSBENCH_ARGS="$SYSBENCH_ARGS	--table-size=1000000"
fi

##  /usr/share/sysbench/oltp_write_only.lua --table-size=250000 --tables=4"
SYSBENCH_TEST="oltp_write_only.lua"

(cd $SERVER_DIR && git log -1 ) > $RESULT_DIR/server-cset.txt
(cd $SERVER_DIR/rocksdb && git log -1 ) > $RESULT_DIR/rocksdb-cset.txt

cat > $RESULT_DIR/info.txt <<END
SERVERNAME=$SERVERNAME
SYSBENCH_TEST=$SYSBENCH_TEST
SERVER_DIR=$SERVER_DIR
SYSBENCH_ARGS=$SYSBENCH_ARGS

END

sleep 3
sysbench $SYSBENCH_ARGS prepare | tee $RESULT_DIR/sysbench-prepare.txt

if [[ $USE_4_CFS ]] ; then
  echo "Splitting 4 tables into different CFs"
  $MYSQL_CMD < make-4-cfs.sql
fi

if [[ $USE_2_CFS ]] ; then
  echo "Splitting 2 tables into different CFs"
  $MYSQL_CMD < make-2-cfs.sql
fi

if [[ $DROP_SECONDARY_INDEX ]]; then
  if [[ $USE_4_CFS ]]; then
      echo "Dropping the secondary indexes"
      for i in `seq 1 4` ; do 
        echo "alter table sbtest.sbtest$i drop key k_1" | $MYSQL_CMD
        echo "show create table sbtest.sbtest$i" | $MYSQL_CMD
      done
  fi
  if [[ $USE_2_CFS ]]; then
    echo "DROP_SECONDARY_INDEX and USE_2_CFS are not supported"
    exit 1
  fi

  echo "Dropping the secondary index"
  echo "alter table sbtest.sbtest1 drop key k_1" | $MYSQL_CMD
  echo "show create table sbtest.sbtest1" | $MYSQL_CMD
fi

sleep 3
$MYSQL_CMD -e "show variables like 'rocksdb%'" > $RESULT_DIR/variables-rocksdb.txt

$MYSQL_CMD -e "show variables" > $RESULT_DIR/variables-all.txt

$MYSQL_CMD -e "select * from $I_S.global_status where variable_name like 'ROCKSDB%'" > $RESULT_DIR/status-before-test.txt


sleep 3
#############################################################################
### Start the profiler
if [[ $USE_PERF ]] ; then
  # Start perf
  sudo sh -c "echo -1 >>  /proc/sys/kernel/perf_event_paranoid"
  #sudo perf record -F 99 -p $MYSQLD_PID -g sleep 60 &
  sudo perf record -F 99 -a -g sleep 60 &
fi


#############################################################################
### Run the benchmark

RUNS="1 5 10 20 40 60 80 100"

if [[ $USE_PERF ]] ; then
  RUNS="100"
fi

for threads in $RUNS ; do
  #echo "THREADS $threads $storage_engine"

  $MYSQL_CMD -e "drop table if exists sbtest.rocksdb_vars;"
  $MYSQL_CMD -e "create table sbtest.rocksdb_vars as select * from $I_S.global_status where variable_name like 'ROCKSDB%'"

  $MYSQL_CMD -e "drop table if exists sbtest.rocksdb_perf_context_global;"
  $MYSQL_CMD -e "create table sbtest.rocksdb_perf_context_global as select * from information_schema.rocksdb_perf_context_global \
	         where stat_type LIKE '%RANGELOCK%' or stat_type LIKE 'LOCK%'"

  SYSBENCH_ALL_ARGS="$SYSBENCH_ARGS --threads=$threads"

  OUTFILE="${RESULT_DIR}/sysbench-run-${threads}.txt"
  sysbench $SYSBENCH_ALL_ARGS run | tee $OUTFILE

  $MYSQL_CMD -e \
  "select A.VARIABLE_NAME, B.VARIABLE_VALUE - A.VARIABLE_VALUE \
   from $I_S.global_status B, sbtest.rocksdb_vars A \
   where B.VARIABLE_NAME=A.VARIABLE_NAME AND B.VARIABLE_VALUE - A.VARIABLE_VALUE >0" > $RESULT_DIR/status-after-test-$threads.txt

  $MYSQL_CMD -e \
   "select A.STAT_TYPE, FORMAT(B.VALUE - A.VALUE,0) \
   from information_schema.rocksdb_perf_context_global B, sbtest.rocksdb_perf_context_global A \
   where B.STAT_TYPE=A.STAT_TYPE AND B.VALUE - A.VALUE >0" > $RESULT_DIR/perf_context-after-test-$threads.txt

done

if [[ $USE_PERF ]] ; then
  CUR_USER=`id -un`
  sudo chown $CUR_USER perf.*
fi


