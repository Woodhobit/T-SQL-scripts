 -- If there are no seeks, scans or lookups, but there are updates this means that SQL Server has not used the index to satisfy a query but still needs to maintain the index. 
 -- Remember that the data from these DMVs is reset when SQL Server is restarted, 
 -- so make sure you have collected data for a long enough period of time to determine which indexes may be good candidates to be dropped.

DECLARE @indexCursor CURSOR;
DECLARE @indexName as NVARCHAR(150);
DECLARE @tableName as NVARCHAR(150);
DECLARE @columnName as NVARCHAR(150);
DECLARE @SQLStringIndexCreation nvarchar(500); 

-- select all unused indexes into temporary table
SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
       I.[NAME] AS [INDEX NAME], 
       USER_SEEKS, 
       USER_SCANS, 
       USER_LOOKUPS, 
       USER_UPDATES
INTO #TempTableIndexes
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S 
       INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
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

-- start deleting
BEGIN
	-- iterate over collection of indexes
	SET @indexCursor = CURSOR FOR
	SELECT [INDEX NAME], [OBJECT NAME] FROM #TempTableIndexes;

	OPEN @indexCursor;
	WHILE @@FETCH_STATUS = 0
		BEGIN
		    -- try to delete the index
			BEGIN TRY
				EXEC(N'DROP INDEX '  + @indexName + ' ON ' + @tableName);
				PRINT cast(@indexName as VARCHAR (50)) + ' - HAS BEEN DELETED';
			END TRY
			BEGIN CATCH
				PRINT cast(@indexName as VARCHAR (50)) +' - Error : ' + CONVERT(VARCHAR, ERROR_NUMBER()) + ':' + ERROR_MESSAGE();
			END CATCH
		
			FETCH NEXT FROM @indexCursor INTO @indexName, @tableName;
		END

	-- release resources
	CLOSE @indexCursor 
	DEALLOCATE @indexCursor 
END;

-- Remove temporary table
DROP TABLE #TempTableIndexes;
