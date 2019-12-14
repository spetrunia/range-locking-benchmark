use sbtest;
alter table sbtest1 rename sbtest1_orig;
alter table sbtest2 rename sbtest2_orig;
alter table sbtest3 rename sbtest3_orig;
alter table sbtest4 rename sbtest4_orig;

CREATE TABLE sbtest1 (
  id int(11) NOT NULL AUTO_INCREMENT,
  k int(11) NOT NULL DEFAULT '0',
  c char(120) NOT NULL DEFAULT '',
  pad char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (id) COMMENT 'cf1_pk',
  KEY k_1 (k) COMMENT 'cf1_sk'
) ENGINE=ROCKSDB CHARSET=latin1;

CREATE TABLE sbtest2 (
  id int(11) NOT NULL AUTO_INCREMENT,
  k int(11) NOT NULL DEFAULT '0',
  c char(120) NOT NULL DEFAULT '',
  pad char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (id) COMMENT 'cf2_pk',
  KEY k_1 (k) COMMENT 'cf2_sk'
) ENGINE=ROCKSDB CHARSET=latin1;

CREATE TABLE sbtest3 (
  id int(11) NOT NULL AUTO_INCREMENT,
  k int(11) NOT NULL DEFAULT '0',
  c char(120) NOT NULL DEFAULT '',
  pad char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (id) COMMENT 'cf3_pk',
  KEY k_1 (k) COMMENT 'cf3_sk'
) ENGINE=ROCKSDB CHARSET=latin1;

CREATE TABLE sbtest4 (
  id int(11) NOT NULL AUTO_INCREMENT,
  k int(11) NOT NULL DEFAULT '0',
  c char(120) NOT NULL DEFAULT '',
  pad char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (id) COMMENT 'cf4_pk',
  KEY k_1 (k) COMMENT 'cf4_sk'
) ENGINE=ROCKSDB CHARSET=latin1;

set rocksdb_commit_in_the_middle=1;
insert into sbtest1 select * from sbtest1_orig;
insert into sbtest2 select * from sbtest2_orig;
insert into sbtest3 select * from sbtest3_orig;
insert into sbtest4 select * from sbtest4_orig;
set rocksdb_commit_in_the_middle=0;
