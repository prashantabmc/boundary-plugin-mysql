Boundary MySQL Plugin
---------------------
Collects metrics from a MySQL database instance.

### Platforms
- Windows
- Linux
- OS X
- SmartOS

### Prerequisites
- node version 0.8.0 or later

### Plugin Setup
None

### Plugin Configuration Fields

|Field Name |Description                                                                                           |
|:----------|:-----------------------------------------------------------------------------------------------------|
|Hostname   |The hostname of the MySQL Server (Socket Path or Hostname is required)                                |
|Port       |Port to use when accessing the MySQL Server                                                           |
|Socket Path|The Socket Path used to access the MySQL Server (Socket Path or Hostname is required)                 |
|Username   |Username to the access the MySQL database                                                             |
|Password   |Pasword to the access the MySQL database                                                              |
|Source     |The Source to display in the legend for the mysql data.  It will default to the hostname of the server|

### Metrics Collected
Tracks the following metrics for [mysql](http://www.mysql.com/)
|Metric Name              |Description                                                                   |
|:------------------------|:-----------------------------------------------------------------------------|
|MySQL Connections        |The number of connection attempts                                             |
|MySQL Aborted Connections|The number of failed connection attempts including those aborted by the client|
|MySQL Bytes In           |bytes in                                                                      |
|MySQL Bytes Out          |bytes out                                                                     |
|MySQL Slow Queries       |The number of queries that have taken more than long_query_time seconds       |
|MySQL Row Modification   |The number of requests to insert/update/delete a row                          |
|MySQL Row Reads          |The number of requests to read a row                                          |
|MySQL Table Locks        |The number of table locks granted                                             |
|MySQL Table Wait Locks   |The number of table locks that required a wait                                |
|MySQL Commits            |The number commits                                                            |
|MySQL Rollback           |The number rollbacks                                                          |
|MySQL Query Memory       |The percentage of used query memory                                           |
|MySQL Query Cache Hits   |The percentage of queries from cache                                          |
|MySQL Query Cache Prunes |The number of queries delete from the query cache                             |

### Installation & Configuration

* The `hostname` used to contact the SQL server, either a hostname or a socketPath is required
* The `port` used to contact the SQL server, defaults to 3306
* The `socketPath` used to contact the SQL server, either a hostname or a socketPath is required
* The `username` used to contact the SQL server
* The `passsword` used to contact the SQL server
* The `source` to prefix the display in the legend for the mysql data.  It will default to the hostname of the server.
