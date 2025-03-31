exec sp_executesql N'WITH DateGenerator AS
(
SELECT CAST(@interval_start_time AS DATETIME) DatePlaceHolder
UNION ALL
SELECT  DATEADD(d, 1, DatePlaceHolder)
FROM    DateGenerator
WHERE   DATEADD(d, 1, DatePlaceHolder) < @interval_end_time
), WaitStats AS
(
SELECT
    ROUND(CONVERT(float, SUM(ws.total_query_wait_time_ms))*1,2) total_query_wait_time
FROM sys.query_store_wait_stats ws
    JOIN sys.query_store_runtime_stats_interval itvl ON itvl.runtime_stats_interval_id = ws.runtime_stats_interval_id
WHERE NOT (itvl.start_time > @interval_end_time OR itvl.end_time < @interval_start_time)
GROUP BY DATEDIFF(d, 0, itvl.end_time)
),
UnionAll AS
(
SELECT
    CONVERT(float, SUM(rs.count_executions)) as total_count_executions,
    ROUND(CONVERT(float, SUM(rs.avg_duration*rs.count_executions))*0.001,2) as total_duration,
    ROUND(CONVERT(float, SUM(rs.avg_cpu_time*rs.count_executions))*0.001,2) as total_cpu_time,
    ROUND(CONVERT(float, SUM(rs.avg_logical_io_reads*rs.count_executions))*8,2) as total_logical_io_reads,
    ROUND(CONVERT(float, SUM(rs.avg_logical_io_writes*rs.count_executions))*8,2) as total_logical_io_writes,
    ROUND(CONVERT(float, SUM(rs.avg_physical_io_reads*rs.count_executions))*8,2) as total_physical_io_reads,
    ROUND(CONVERT(float, SUM(rs.avg_clr_time*rs.count_executions))*0.001,2) as total_clr_time,
    ROUND(CONVERT(float, SUM(rs.avg_dop*rs.count_executions))*1,0) as total_dop,
    ROUND(CONVERT(float, SUM(rs.avg_query_max_used_memory*rs.count_executions))*8,2) as total_query_max_used_memory,
    ROUND(CONVERT(float, SUM(rs.avg_rowcount*rs.count_executions))*1,0) as total_rowcount,
    ROUND(CONVERT(float, SUM(rs.avg_log_bytes_used*rs.count_executions))*0.0009765625,2) as total_log_bytes_used,
    ROUND(CONVERT(float, SUM(rs.avg_tempdb_space_used*rs.count_executions))*8,2) as total_tempdb_space_used,
    DATEADD(d, ((DATEDIFF(d, 0, rs.last_execution_time))),0 ) as bucket_start,
    DATEADD(d, (1 + (DATEDIFF(d, 0, rs.last_execution_time))), 0) as bucket_end
FROM sys.query_store_runtime_stats rs
WHERE NOT (rs.first_execution_time > @interval_end_time OR rs.last_execution_time < @interval_start_time)
GROUP BY DATEDIFF(d, 0, rs.last_execution_time)
)
SELECT 
    total_count_executions,
    total_duration,
    total_cpu_time,
    total_logical_io_reads,
    total_logical_io_writes,
    total_physical_io_reads,
    total_clr_time,
    total_dop,
    total_query_max_used_memory,
    total_rowcount,
    total_log_bytes_used,
    total_tempdb_space_used,
    total_query_wait_time,
    SWITCHOFFSET(bucket_start, DATEPART(tz, @interval_start_time)) , SWITCHOFFSET(bucket_end, DATEPART(tz, @interval_start_time))
FROM
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY bucket_start ORDER BY bucket_start, total_duration DESC) AS RowNumber
FROM UnionAll , WaitStats
) as UnionAllResults
WHERE UnionAllResults.RowNumber = 1
OPTION (MAXRECURSION 0)',N'@interval_start_time datetimeoffset(7),@interval_end_time datetimeoffset(7)',@interval_start_time='2025-02-28 13:35:58.3415888 -05:00',@interval_end_time='2025-03-28 14:35:58.3415888 -04:00'