# MySQL Graphdat Plugin

#### Tracks the following metrics for [mysql](http://www.mysql.com/)*
* MYSQL_CONNECTIONS - THe number of connections
* MYSQL_ABORTED_CONNECTIONS - The number of aborted conections
* MYSQL_BYTES_IN - Bytes In
* MYSQL_BYTES_OUT - Bytes Out
* MYSQL_SLOW_QUERIES - The number of queries exceeding the slow query time
* MYSQL_ROW_MODIFICATIONS - The number of rows modified (deletes, writes, updates)
* MYSQL_ROW_READS - The number of rows reads
* MYSQL_TABLE_LOCKS - The number of tables locks granted immediately
* MYSQL_TABLE_LOCKS_WAIT - The number of table locks requring a wait
* MYSQL_COMMITS - The number of commits
* MYSQL_ROLLBACKS - The number of rollbacks
* MYSQL_QCACHE_MEMORY - The amount of memory devoted to the query cache
* MYSQL_QCACHE_HITS - Percentage of selects that were pulled from the cache
* MYSQL_QCACHE_PRUNES - The number of cache entries that were pruned due to low memory

### Installation & Configuration

* The `hostname` used to contact the SQL server, either a hostname or a socketPath is required
* The `port` used to contact the SQL server, defaults to 3306
* The `socketPath` used to contact the SQL server, either a hostname or a socketPath is required
* The `username` used to contact the SQL server
* The `passsword` used to contact the SQL server
* The `source` to prefix the display in the legend for the mysql data.  It will default to the hostname of the server.
