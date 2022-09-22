<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_sumologic"></a> [sumologic](#requirement\_sumologic) | >= 2.18.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |
| <a name="provider_sumologic"></a> [sumologic](#provider\_sumologic) | 2.18.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_Cassandra-BlockedRepairTasks"></a> [Cassandra-BlockedRepairTasks](#module\_Cassandra-BlockedRepairTasks) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-CacheHitRatebelow85Percent"></a> [Cassandra-CacheHitRatebelow85Percent](#module\_Cassandra-CacheHitRatebelow85Percent) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-CompactionTaskPending"></a> [Cassandra-CompactionTaskPending](#module\_Cassandra-CompactionTaskPending) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-HighCommitlogPendingTasks"></a> [Cassandra-HighCommitlogPendingTasks](#module\_Cassandra-HighCommitlogPendingTasks) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-HighNumberofCompactionExecutorBlockedTasks"></a> [Cassandra-HighNumberofCompactionExecutorBlockedTasks](#module\_Cassandra-HighNumberofCompactionExecutorBlockedTasks) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-HighNumberofFlushWriterBlockedTasks"></a> [Cassandra-HighNumberofFlushWriterBlockedTasks](#module\_Cassandra-HighNumberofFlushWriterBlockedTasks) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-HighTombstoneScanning"></a> [Cassandra-HighTombstoneScanning](#module\_Cassandra-HighTombstoneScanning) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-IncreaseinAuthenticationFailures"></a> [Cassandra-IncreaseinAuthenticationFailures](#module\_Cassandra-IncreaseinAuthenticationFailures) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-NodeDown"></a> [Cassandra-NodeDown](#module\_Cassandra-NodeDown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Cassandra-RepairTasksPending"></a> [Cassandra-RepairTasksPending](#module\_Cassandra-RepairTasksPending) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-BucketNotReady"></a> [Couchbase-BucketNotReady](#module\_Couchbase-BucketNotReady) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-HighCPUUsage"></a> [Couchbase-HighCPUUsage](#module\_Couchbase-HighCPUUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-HighMemoryUsage"></a> [Couchbase-HighMemoryUsage](#module\_Couchbase-HighMemoryUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-NodeDown"></a> [Couchbase-NodeDown](#module\_Couchbase-NodeDown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-NodeNotRespond"></a> [Couchbase-NodeNotRespond](#module\_Couchbase-NodeNotRespond) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-TooManyErrorQueriesonBuckets"></a> [Couchbase-TooManyErrorQueriesonBuckets](#module\_Couchbase-TooManyErrorQueriesonBuckets) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Couchbase-TooManyLoginFailures"></a> [Couchbase-TooManyLoginFailures](#module\_Couchbase-TooManyLoginFailures) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-ClusterRed"></a> [Elasticsearch-ClusterRed](#module\_Elasticsearch-ClusterRed) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-ClusterYellow"></a> [Elasticsearch-ClusterYellow](#module\_Elasticsearch-ClusterYellow) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-DiskOutofSpace"></a> [Elasticsearch-DiskOutofSpace](#module\_Elasticsearch-DiskOutofSpace) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-DiskSpaceLow"></a> [Elasticsearch-DiskSpaceLow](#module\_Elasticsearch-DiskSpaceLow) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-ErrorLogTooMany"></a> [Elasticsearch-ErrorLogTooMany](#module\_Elasticsearch-ErrorLogTooMany) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-HealthyDataNodes"></a> [Elasticsearch-HealthyDataNodes](#module\_Elasticsearch-HealthyDataNodes) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-HealthyNodes"></a> [Elasticsearch-HealthyNodes](#module\_Elasticsearch-HealthyNodes) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-HeapUsageTooHigh"></a> [Elasticsearch-HeapUsageTooHigh](#module\_Elasticsearch-HeapUsageTooHigh) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-HeapUsageWarning"></a> [Elasticsearch-HeapUsageWarning](#module\_Elasticsearch-HeapUsageWarning) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-InitializingShardsTooLong"></a> [Elasticsearch-InitializingShardsTooLong](#module\_Elasticsearch-InitializingShardsTooLong) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-PendingTasks"></a> [Elasticsearch-PendingTasks](#module\_Elasticsearch-PendingTasks) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-QueryTimeSlow"></a> [Elasticsearch-QueryTimeSlow](#module\_Elasticsearch-QueryTimeSlow) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-QueryTimeTooSlow"></a> [Elasticsearch-QueryTimeTooSlow](#module\_Elasticsearch-QueryTimeTooSlow) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-RelocatingShardsTooLong"></a> [Elasticsearch-RelocatingShardsTooLong](#module\_Elasticsearch-RelocatingShardsTooLong) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-TooManySlowQuery"></a> [Elasticsearch-TooManySlowQuery](#module\_Elasticsearch-TooManySlowQuery) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Elasticsearch-UnassignedShards"></a> [Elasticsearch-UnassignedShards](#module\_Elasticsearch-UnassignedShards) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Connectionrefused"></a> [MariaDB-Connectionrefused](#module\_MariaDB-Connectionrefused) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-ExcessiveSlowQueryDetected"></a> [MariaDB-ExcessiveSlowQueryDetected](#module\_MariaDB-ExcessiveSlowQueryDetected) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Followerreplicationlagdetected"></a> [MariaDB-Followerreplicationlagdetected](#module\_MariaDB-Followerreplicationlagdetected) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-HighInnodbbufferpoolutilization"></a> [MariaDB-HighInnodbbufferpoolutilization](#module\_MariaDB-HighInnodbbufferpoolutilization) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Highaveragequeryruntime"></a> [MariaDB-Highaveragequeryruntime](#module\_MariaDB-Highaveragequeryruntime) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Instancedown"></a> [MariaDB-Instancedown](#module\_MariaDB-Instancedown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Largenumberofabortedconnections"></a> [MariaDB-Largenumberofabortedconnections](#module\_MariaDB-Largenumberofabortedconnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Largenumberofinternalconnectionerrors"></a> [MariaDB-Largenumberofinternalconnectionerrors](#module\_MariaDB-Largenumberofinternalconnectionerrors) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Largenumberofslowqueries"></a> [MariaDB-Largenumberofslowqueries](#module\_MariaDB-Largenumberofslowqueries) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Largenumberofstatementerrors"></a> [MariaDB-Largenumberofstatementerrors](#module\_MariaDB-Largenumberofstatementerrors) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-Largenumberofstatementwarnings"></a> [MariaDB-Largenumberofstatementwarnings](#module\_MariaDB-Largenumberofstatementwarnings) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-NoindexusedintheSQLstatements"></a> [MariaDB-NoindexusedintheSQLstatements](#module\_MariaDB-NoindexusedintheSQLstatements) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MariaDB-SlaveServerError"></a> [MariaDB-SlaveServerError](#module\_MariaDB-SlaveServerError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-AuthenticationError"></a> [Memcached-AuthenticationError](#module\_Memcached-AuthenticationError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-CacheHitRatio"></a> [Memcached-CacheHitRatio](#module\_Memcached-CacheHitRatio) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-CommandsError"></a> [Memcached-CommandsError](#module\_Memcached-CommandsError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-ConnectionYields"></a> [Memcached-ConnectionYields](#module\_Memcached-ConnectionYields) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-CurrentConnections"></a> [Memcached-CurrentConnections](#module\_Memcached-CurrentConnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-HighMemoryUsage"></a> [Memcached-HighMemoryUsage](#module\_Memcached-HighMemoryUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-ListenDisabled"></a> [Memcached-ListenDisabled](#module\_Memcached-ListenDisabled) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Memcached-Uptime"></a> [Memcached-Uptime](#module\_Memcached-Uptime) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-InstanceDown"></a> [MongoDB-InstanceDown](#module\_MongoDB-InstanceDown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-MissingPrimary"></a> [MongoDB-MissingPrimary](#module\_MongoDB-MissingPrimary) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ReplicationError"></a> [MongoDB-ReplicationError](#module\_MongoDB-ReplicationError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ReplicationHeartbeatError"></a> [MongoDB-ReplicationHeartbeatError](#module\_MongoDB-ReplicationHeartbeatError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ReplicationLag"></a> [MongoDB-ReplicationLag](#module\_MongoDB-ReplicationLag) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-SecondaryNodeReplicationFailure"></a> [MongoDB-SecondaryNodeReplicationFailure](#module\_MongoDB-SecondaryNodeReplicationFailure) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ShardingBalancerFailure"></a> [MongoDB-ShardingBalancerFailure](#module\_MongoDB-ShardingBalancerFailure) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ShardingChunkSplitFailure"></a> [MongoDB-ShardingChunkSplitFailure](#module\_MongoDB-ShardingChunkSplitFailure) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ShardingError"></a> [MongoDB-ShardingError](#module\_MongoDB-ShardingError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-ShardingWarning"></a> [MongoDB-ShardingWarning](#module\_MongoDB-ShardingWarning) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-SlowQueries"></a> [MongoDB-SlowQueries](#module\_MongoDB-SlowQueries) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-TooManyConnections"></a> [MongoDB-TooManyConnections](#module\_MongoDB-TooManyConnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-TooManyCursorsOpen"></a> [MongoDB-TooManyCursorsOpen](#module\_MongoDB-TooManyCursorsOpen) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MongoDB-TooManyCursorsTimeouts"></a> [MongoDB-TooManyCursorsTimeouts](#module\_MongoDB-TooManyCursorsTimeouts) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Connectionrefused"></a> [MySQL-Connectionrefused](#module\_MySQL-Connectionrefused) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-ExcessiveSlowQueryDetected"></a> [MySQL-ExcessiveSlowQueryDetected](#module\_MySQL-ExcessiveSlowQueryDetected) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Followerreplicationlagdetected"></a> [MySQL-Followerreplicationlagdetected](#module\_MySQL-Followerreplicationlagdetected) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-HighInnodbbufferpoolutilization"></a> [MySQL-HighInnodbbufferpoolutilization](#module\_MySQL-HighInnodbbufferpoolutilization) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Highaveragequeryruntime"></a> [MySQL-Highaveragequeryruntime](#module\_MySQL-Highaveragequeryruntime) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Instancedown"></a> [MySQL-Instancedown](#module\_MySQL-Instancedown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Largenumberofabortedconnections"></a> [MySQL-Largenumberofabortedconnections](#module\_MySQL-Largenumberofabortedconnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Largenumberofinternalconnectionerrors"></a> [MySQL-Largenumberofinternalconnectionerrors](#module\_MySQL-Largenumberofinternalconnectionerrors) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Largenumberofslowqueries"></a> [MySQL-Largenumberofslowqueries](#module\_MySQL-Largenumberofslowqueries) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Largenumberofstatementerrors"></a> [MySQL-Largenumberofstatementerrors](#module\_MySQL-Largenumberofstatementerrors) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-Largenumberofstatementwarnings"></a> [MySQL-Largenumberofstatementwarnings](#module\_MySQL-Largenumberofstatementwarnings) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_MySQL-NoindexusedintheSQLstatements"></a> [MySQL-NoindexusedintheSQLstatements](#module\_MySQL-NoindexusedintheSQLstatements) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-AdminRestrictedCommandExecution"></a> [Oracle-AdminRestrictedCommandExecution](#module\_Oracle-AdminRestrictedCommandExecution) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-ArchivalLogCreation"></a> [Oracle-ArchivalLogCreation](#module\_Oracle-ArchivalLogCreation) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-BlockCorruption"></a> [Oracle-BlockCorruption](#module\_Oracle-BlockCorruption) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-DatabaseCrash"></a> [Oracle-DatabaseCrash](#module\_Oracle-DatabaseCrash) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-DatabaseDown"></a> [Oracle-DatabaseDown](#module\_Oracle-DatabaseDown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-Deadlock"></a> [Oracle-Deadlock](#module\_Oracle-Deadlock) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-FatalNIConnectError"></a> [Oracle-FatalNIConnectError](#module\_Oracle-FatalNIConnectError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-HighCPUUsage"></a> [Oracle-HighCPUUsage](#module\_Oracle-HighCPUUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-InternalErrors"></a> [Oracle-InternalErrors](#module\_Oracle-InternalErrors) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-LoginFail"></a> [Oracle-LoginFail](#module\_Oracle-LoginFail) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-PossibleInappropriateActivity"></a> [Oracle-PossibleInappropriateActivity](#module\_Oracle-PossibleInappropriateActivity) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-ProcessLimitCritical"></a> [Oracle-ProcessLimitCritical](#module\_Oracle-ProcessLimitCritical) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-ProcessLimitWarning"></a> [Oracle-ProcessLimitWarning](#module\_Oracle-ProcessLimitWarning) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-SessionCritical"></a> [Oracle-SessionCritical](#module\_Oracle-SessionCritical) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-SessionWarning"></a> [Oracle-SessionWarning](#module\_Oracle-SessionWarning) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-TNSError"></a> [Oracle-TNSError](#module\_Oracle-TNSError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-TablespacesOutofSpace"></a> [Oracle-TablespacesOutofSpace](#module\_Oracle-TablespacesOutofSpace) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-TablespacesSpaceLow"></a> [Oracle-TablespacesSpaceLow](#module\_Oracle-TablespacesSpaceLow) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-UnableToExtendTablespace"></a> [Oracle-UnableToExtendTablespace](#module\_Oracle-UnableToExtendTablespace) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-UnauthorizedCommandExecution"></a> [Oracle-UnauthorizedCommandExecution](#module\_Oracle-UnauthorizedCommandExecution) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-UserLimitCritical"></a> [Oracle-UserLimitCritical](#module\_Oracle-UserLimitCritical) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Oracle-UserLimitWarning"></a> [Oracle-UserLimitWarning](#module\_Oracle-UserLimitWarning) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-AccessFromHighlyMaliciousSources"></a> [Postgresql-AccessFromHighlyMaliciousSources](#module\_Postgresql-AccessFromHighlyMaliciousSources) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-HighRateDeadlock"></a> [Postgresql-HighRateDeadlock](#module\_Postgresql-HighRateDeadlock) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-HighRateofStatementTimeout"></a> [Postgresql-HighRateofStatementTimeout](#module\_Postgresql-HighRateofStatementTimeout) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-HighReplicationLag"></a> [Postgresql-HighReplicationLag](#module\_Postgresql-HighReplicationLag) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-InstanceDown"></a> [Postgresql-InstanceDown](#module\_Postgresql-InstanceDown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-LowCommits"></a> [Postgresql-LowCommits](#module\_Postgresql-LowCommits) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-SSLCompressionActive"></a> [Postgresql-SSLCompressionActive](#module\_Postgresql-SSLCompressionActive) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-SlowQueries"></a> [Postgresql-SlowQueries](#module\_Postgresql-SlowQueries) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-TooManyConnections"></a> [Postgresql-TooManyConnections](#module\_Postgresql-TooManyConnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Postgresql-TooManyLocksAcquired"></a> [Postgresql-TooManyLocksAcquired](#module\_Postgresql-TooManyLocksAcquired) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-HighCPUUsage"></a> [Redis-HighCPUUsage](#module\_Redis-HighCPUUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-Instancedown"></a> [Redis-Instancedown](#module\_Redis-Instancedown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-Master-SlaveIO"></a> [Redis-Master-SlaveIO](#module\_Redis-Master-SlaveIO) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-MemFragmentationRatioHigherthan"></a> [Redis-MemFragmentationRatioHigherthan](#module\_Redis-MemFragmentationRatioHigherthan) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-MissingMaster"></a> [Redis-MissingMaster](#module\_Redis-MissingMaster) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-OutOfMemory"></a> [Redis-OutOfMemory](#module\_Redis-OutOfMemory) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-RejectedConnections"></a> [Redis-RejectedConnections](#module\_Redis-RejectedConnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-ReplicaLag"></a> [Redis-ReplicaLag](#module\_Redis-ReplicaLag) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-ReplicationBroken"></a> [Redis-ReplicationBroken](#module\_Redis-ReplicationBroken) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-ReplicationOffset"></a> [Redis-ReplicationOffset](#module\_Redis-ReplicationOffset) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_Redis-TooManyConnections"></a> [Redis-TooManyConnections](#module\_Redis-TooManyConnections) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-AppDomain"></a> [SQLServer-AppDomain](#module\_SQLServer-AppDomain) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-BackupFail"></a> [SQLServer-BackupFail](#module\_SQLServer-BackupFail) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-CpuHighUsage"></a> [SQLServer-CpuHighUsage](#module\_SQLServer-CpuHighUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-Deadlock"></a> [SQLServer-Deadlock](#module\_SQLServer-Deadlock) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-DiskUsage"></a> [SQLServer-DiskUsage](#module\_SQLServer-DiskUsage) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-InstanceDown"></a> [SQLServer-InstanceDown](#module\_SQLServer-InstanceDown) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-InsufficientSpace"></a> [SQLServer-InsufficientSpace](#module\_SQLServer-InsufficientSpace) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-LoginFail"></a> [SQLServer-LoginFail](#module\_SQLServer-LoginFail) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-MirroringError"></a> [SQLServer-MirroringError](#module\_SQLServer-MirroringError) | SumoLogic/sumo-logic-monitor/sumologic | n/a |
| <a name="module_SQLServer-ProcessesBlocked"></a> [SQLServer-ProcessesBlocked](#module\_SQLServer-ProcessesBlocked) | SumoLogic/sumo-logic-monitor/sumologic | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.install_app_component_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_cassandra_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_couchbase_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_elasticsearch_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_mariadb_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_memcached_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_mongodb_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_mysql_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_oracle_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_postgresql_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_redis_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_sqlserver_app](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [sumologic_content_permission.share_with_org](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/content_permission) | resource |
| [sumologic_field.component](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_cluster](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_cluster_address](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_cluster_port](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.db_system](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.environment](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_cluster](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_cluster_address](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_cluster_port](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field.pod_labels_db_system](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field) | resource |
| [sumologic_field_extraction_rule.SumoLogicFieldExtractionRulesForDatabase](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/field_extraction_rule) | resource |
| [sumologic_folder.root_apps_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/folder) | resource |
| [sumologic_hierarchy.application_component_view](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/hierarchy) | resource |
| [sumologic_monitor_folder.cassandra_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.couchbase_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.elasticsearch_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.mariadb_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.memcached_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.mongodb_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.mysql_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.oracle_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.postgresql_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.redis_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.root_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_monitor_folder.sqlserver_monitor_folder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/resources/monitor_folder) | resource |
| [sumologic_admin_recommended_folder.adminFolder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/data-sources/admin_recommended_folder) | data source |
| [sumologic_personal_folder.personalFolder](https://registry.terraform.io/providers/SumoLogic/sumologic/latest/docs/data-sources/personal_folder) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apps_folder_installation_location"></a> [apps\_folder\_installation\_location](#input\_apps\_folder\_installation\_location) | Indicates where to install the app folder. Enter "Personal Folder" for installing in "Personal" folder and "Admin Recommended Folder" for installing in "Admin Recommended" folder. | `string` | `"Personal Folder"` | no |
| <a name="input_apps_folder_name"></a> [apps\_folder\_name](#input\_apps\_folder\_name) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br>            Default value will be: Applications Component Solutions | `string` | `"Applications Component Solution - Apps"` | no |
| <a name="input_cassandra_data_source"></a> [cassandra\_data\_source](#input\_cassandra\_data\_source) | Sumo Logic cassandra cluster Filter. For eg: db\_cluster=cassandra.prod.01 | `string` | `"db_system=cassandra"` | no |
| <a name="input_cassandra_monitor_folder"></a> [cassandra\_monitor\_folder](#input\_cassandra\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Cassandra"` | no |
| <a name="input_components_on_kubernetes_deployment"></a> [components\_on\_kubernetes\_deployment](#input\_components\_on\_kubernetes\_deployment) | Provide comma separated list of application components for which sumologic resources needs to be created. Allowed values are "memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle". | `string` | `""` | no |
| <a name="input_components_on_non_kubernetes_deployment"></a> [components\_on\_non\_kubernetes\_deployment](#input\_components\_on\_non\_kubernetes\_deployment) | Provide comma separated list of application components for which sumologic resources needs to be created. Allowed values are "memcached,cassandra,elasticsearch,sqlserver,mongodb,mysql,postgresql,redis,mariadb,couchbase,oracle". | `string` | `""` | no |
| <a name="input_connection_notifications_critical"></a> [connection\_notifications\_critical](#input\_connection\_notifications\_critical) | Connection Notifications to be sent by the critical alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      connection_id         = string,<br>      payload_override      = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_connection_notifications_missingdata"></a> [connection\_notifications\_missingdata](#input\_connection\_notifications\_missingdata) | Connection Notifications to be sent by the missing data alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      connection_id         = string,<br>      payload_override      = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_connection_notifications_warning"></a> [connection\_notifications\_warning](#input\_connection\_notifications\_warning) | Connection Notifications to be sent by the warning alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      connection_id         = string,<br>      payload_override      = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_couchbase_data_source"></a> [couchbase\_data\_source](#input\_couchbase\_data\_source) | Sumo Logic couchbase cluster Filter. For eg: db\_cluster=couchbase.prod.01 | `string` | `"db_system=couchbase"` | no |
| <a name="input_couchbase_monitor_folder"></a> [couchbase\_monitor\_folder](#input\_couchbase\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Couchbase"` | no |
| <a name="input_elasticsearch_data_source"></a> [elasticsearch\_data\_source](#input\_elasticsearch\_data\_source) | Sumo Logic elasticsearch cluster Filter. For eg: db\_cluster=elasticsearch.prod.01 | `string` | `"db_system=elasticsearch"` | no |
| <a name="input_elasticsearch_monitor_folder"></a> [elasticsearch\_monitor\_folder](#input\_elasticsearch\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Elasticsearch"` | no |
| <a name="input_email_notifications_critical"></a> [email\_notifications\_critical](#input\_email\_notifications\_critical) | Email Notifications to be sent by the critical alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      recipients            = list(string),<br>      subject               = string,<br>      time_zone             = string,<br>      message_body          = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_email_notifications_missingdata"></a> [email\_notifications\_missingdata](#input\_email\_notifications\_missingdata) | Email Notifications to be sent by the missing data alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      recipients            = list(string),<br>      subject               = string,<br>      time_zone             = string,<br>      message_body          = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_email_notifications_warning"></a> [email\_notifications\_warning](#input\_email\_notifications\_warning) | Email Notifications to be sent by the warning alert. | <pre>list(object(<br>    {<br>      connection_type       = string,<br>      recipients            = list(string),<br>      subject               = string,<br>      time_zone             = string,<br>      message_body          = string,<br>      run_for_trigger_types = list(string)<br>    }<br>  ))</pre> | n/a | yes |
| <a name="input_group_notifications"></a> [group\_notifications](#input\_group\_notifications) | Whether or not to group notifications for individual items that meet the trigger condition. Defaults to true. | `bool` | `true` | no |
| <a name="input_mariadb_data_source"></a> [mariadb\_data\_source](#input\_mariadb\_data\_source) | Sumo Logic mariadb cluster Filter. For eg: db\_cluster=mariadb.prod.01 | `string` | `"db_system=mariadb"` | no |
| <a name="input_mariadb_monitor_folder"></a> [mariadb\_monitor\_folder](#input\_mariadb\_monitor\_folder) | Folder where monitors will be created. | `string` | `"MariaDB"` | no |
| <a name="input_memcached_data_source"></a> [memcached\_data\_source](#input\_memcached\_data\_source) | Sumo Logic Memcached cluster Filter. For eg: db\_cluster=memcached.prod.01 | `string` | `"db_system=memcached"` | no |
| <a name="input_memcached_monitor_folder"></a> [memcached\_monitor\_folder](#input\_memcached\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Memcached"` | no |
| <a name="input_mongodb_data_source"></a> [mongodb\_data\_source](#input\_mongodb\_data\_source) | Sumo Logic MongoDB cluster Filter. For eg: db\_cluster=mongodb.prod.01 | `string` | `"db_system=mongodb"` | no |
| <a name="input_mongodb_monitor_folder"></a> [mongodb\_monitor\_folder](#input\_mongodb\_monitor\_folder) | Folder where monitors will be created. | `string` | `"MongoDB"` | no |
| <a name="input_monitors_disabled"></a> [monitors\_disabled](#input\_monitors\_disabled) | Whether the monitors are enabled or not? | `bool` | `true` | no |
| <a name="input_monitors_folder_name"></a> [monitors\_folder\_name](#input\_monitors\_folder\_name) | Provide a folder name where all the apps will be installed under the Personal folder of the user whose access keys you have entered.<br>            Default value will be: Applications Component Solutions | `string` | `"Applications Component Solution - Monitors"` | no |
| <a name="input_mysql_data_source"></a> [mysql\_data\_source](#input\_mysql\_data\_source) | Sumo Logic mysql cluster Filter. For eg: db\_cluster=mysql.prod.01 | `string` | `"db_system=mysql"` | no |
| <a name="input_mysql_monitor_folder"></a> [mysql\_monitor\_folder](#input\_mysql\_monitor\_folder) | Folder where monitors will be created. | `string` | `"MySQL"` | no |
| <a name="input_oracle_data_source"></a> [oracle\_data\_source](#input\_oracle\_data\_source) | Sumo Logic oracle cluster Filter. For eg: db\_cluster=oracle.prod.01 | `string` | `"db_system=oracle"` | no |
| <a name="input_oracle_monitor_folder"></a> [oracle\_monitor\_folder](#input\_oracle\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Oracle"` | no |
| <a name="input_postgresql_data_source"></a> [postgresql\_data\_source](#input\_postgresql\_data\_source) | Sumo Logic postgresql cluster Filter. For eg: db\_cluster=postgresql.prod.01 | `string` | `"db_system=postgresql"` | no |
| <a name="input_postgresql_monitor_folder"></a> [postgresql\_monitor\_folder](#input\_postgresql\_monitor\_folder) | Folder where monitors will be created. | `string` | `"PostgreSQL"` | no |
| <a name="input_redis_data_source"></a> [redis\_data\_source](#input\_redis\_data\_source) | Sumo Logic Redis cluster Filter. For eg: db\_cluster=redis.prod.01 | `string` | `"db_system=redis"` | no |
| <a name="input_redis_monitor_folder"></a> [redis\_monitor\_folder](#input\_redis\_monitor\_folder) | Folder where monitors will be created. | `string` | `"Redis"` | no |
| <a name="input_share_apps_folder_with_org"></a> [share\_apps\_folder\_with\_org](#input\_share\_apps\_folder\_with\_org) | Indicates if Apps folder should be shared (view access) with entire organization. true to enable; false to disable. | `bool` | `true` | no |
| <a name="input_sqlserver_data_source"></a> [sqlserver\_data\_source](#input\_sqlserver\_data\_source) | Sumo Logic sqlserver cluster Filter. For eg: db\_cluster=sqlserver.prod.01 | `string` | `"db_system=sqlserver"` | no |
| <a name="input_sqlserver_monitor_folder"></a> [sqlserver\_monitor\_folder](#input\_sqlserver\_monitor\_folder) | Folder where monitors will be created. | `string` | `"SQL Server"` | no |
| <a name="input_sumologic_access_id"></a> [sumologic\_access\_id](#input\_sumologic\_access\_id) | Sumo Logic Access ID. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_access_key"></a> [sumologic\_access\_key](#input\_sumologic\_access\_key) | Sumo Logic Access Key. Visit https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key | `string` | n/a | yes |
| <a name="input_sumologic_environment"></a> [sumologic\_environment](#input\_sumologic\_environment) | Enter au, ca, de, eu, jp, us2, in, fed or us1. For more information on Sumo Logic deployments visit https://help.sumologic.com/APIs/General-API-Information/Sumo-Logic-Endpoints-and-Firewall-Security | `string` | n/a | yes |
| <a name="input_sumologic_organization_id"></a> [sumologic\_organization\_id](#input\_sumologic\_organization\_id) | You can find your org on the Preferences page in the Sumo Logic UI. For more information, see the Preferences Page topic. Your org ID will be used to configure the IAM Role for Sumo Logic AWS Sources."<br>            For more details, visit https://help.sumologic.com/01Start-Here/05Customize-Your-Sumo-Logic-Experience/Preferences-Page | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ApplicationComponentAppsFolder"></a> [ApplicationComponentAppsFolder](#output\_ApplicationComponentAppsFolder) | Go to this link to view the apps folder |
| <a name="output_ApplicationComponentMonitorsFolder"></a> [ApplicationComponentMonitorsFolder](#output\_ApplicationComponentMonitorsFolder) | Go to this link to view the monitors folder |
<!-- END_TF_DOCS -->