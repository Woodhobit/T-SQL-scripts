DECLARE @indexCursor CURSOR;
DECLARE @indexName as NVARCHAR(150);
DECLARE @tableName as NVARCHAR(150);
DECLARE @columnName as NVARCHAR(150);
DECLARE @SQLStringIndexCreation nvarchar(500); 

--find all Guids fields without index 

SELECT 
     t.[NAME] AS [Table],
	 C.[NAME] AS [Column]
INTO #TempGuidsWithoutIndexes
FROM SYS.COLUMNS AS C 
	INNER JOIN SYS.TABLES AS T ON C.OBJECT_ID = T.OBJECT_ID 
WHERE 
      T.is_ms_shipped = 0
     AND (C.[NAME] LIKE '%GUID%' OR C.[NAME] LIKE '%Guid%')
EXCEPT
SELECT 
   OBJECT_NAME(IC.OBJECT_ID) AS [Table],
   c.[NAME] AS [Column]
FROM 
   SYS.INDEX_COLUMNS  AS IC
   INNER JOIN SYS.ALL_COLUMNS AS C ON  IC.OBJECT_ID = c.OBJECT_ID  AND  IC.COLUMN_ID = C.COLUMN_ID
   INNER JOIN SYS.OBJECTS  AS O ON IC.OBJECT_ID = O.OBJECT_ID 
WHERE 
   IC.KEY_ORDINAL = 1
   AND O.IS_MS_SHIPPED = 0

-- start creating indexes on Guid fields
BEGIN
	-- iterate over collection of indexes
	SET @indexCursor = CURSOR FOR
	SELECT [Table], [Column] FROM #TempGuidsWithoutIndexes;

	OPEN @indexCursor;

	WHILE @@FETCH_STATUS = 0
		BEGIN
		    -- try to delete the index
			BEGIN TRY
				SET @indexName = 'IX_'+ @columnName;
				SET @SQLStringIndexCreation = N'CREATE NONCLUSTERED INDEX ['+@indexName+'] ON [dbo].['+@tableName+'](['+@columnName+'] ASC)';
				EXEC(@SQLStringIndexCreation);
				PRINT cast(@indexName as VARCHAR (50)) + ' - HAS BEEN CREATED';
			END TRY
			BEGIN CATCH
				PRINT cast(@tableName as VARCHAR (50))+'.'+cast(@columnName as VARCHAR (50)) +' - Error : ' + CONVERT(VARCHAR, ERROR_NUMBER()) + ':' + ERROR_MESSAGE();
			END CATCH
		
			FETCH NEXT FROM @indexCursor INTO @tableName, @columnName;
		END

	-- release resources
	CLOSE @indexCursor 
	DEALLOCATE @indexCursor 
END;

-- Remove temporary table
DROP TABLE #TempGuidsWithoutIndexes;
