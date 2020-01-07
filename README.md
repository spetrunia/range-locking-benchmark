# range-locking-benchmark
Benchmark Range Locking for MyRocks

The scripts assume the OS is Ubuntu.

To set up everything and do a benchmark run, run this:

```
git clone https://github.com/spetrunia/range-locking-benchmark.git
cd range-locking-benchmark
bash setup-os.sh
bash setup-fbmysql-nov.sh
bash run-all.sh
```
# Uses and results
See
* https://jira.mariadb.org/browse/MDEV-18856
* https://jira.mariadb.org/browse/MDEV-21186
