--SYS.DM_DB_INDEX_USAGE_STATS shows you how many times the index was used for user queries

--The seeks refer to how many times an index seek occurred for that index.  A seek is the fastest way to access the data, so this is good.
--The scans refers to how many times an index scan occurred for that index.  A scan is when multiple rows of data had to be searched to find the data.  Scans are something you want to try to avoid.
--The lookups refer to how many times the query required data to be pulled from the clustered index or the heap (does not have a clustered index).  Lookups are also something you want to try to avoid.
--The updates refers to how many times the index was updated due to data changes which should correspond to the first query above.

--If there are indexes with no seeks, scans or lookups, but there are updates this means that SQL Server has not used the 
--index to satisfy a query but still needs to maintain the index

SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
       I.[NAME] AS [INDEX NAME], 
       USER_SEEKS, 
       USER_SCANS, 
       USER_LOOKUPS, 
       USER_UPDATES
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S 
       INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1 AND S.DATABASE_ID = DB_ID()
       AND S.DATABASE_ID = DB_ID()
	   AND USER_SEEKS = 0 
	   AND USER_SCANS = 0 
	   AND USER_LOOKUPS = 0 
	   AND USER_UPDATES <> 0 --This line excludes indexes SQL Server hasn’t done any work with
	   AND I.IS_PRIMARY_KEY = 0 --This line excludes primary key constarint
       AND I.IS_UNIQUE = 0 --This line excludes unique key constarint
	   AND I.[NAME] IS NOT NULL
ORDER BY
    S.USER_UPDATES DESC;
