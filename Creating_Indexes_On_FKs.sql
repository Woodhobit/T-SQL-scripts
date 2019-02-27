DECLARE @indexCursor CURSOR;
DECLARE @indexName as NVARCHAR(150);
DECLARE @tableName as NVARCHAR(150);
DECLARE @columnName as NVARCHAR(150);
DECLARE @SQLStringIndexCreation nvarchar(500); 

-- find all foreign keys without index
SELECT 
   OBJECT_NAME(A.PARENT_OBJECT_ID) AS [Table],
   B.[NAME] AS [FK_Column]
INTO #TempFKWithoutIndexes
FROM 
   SYS.FOREIGN_KEY_COLUMNS AS A
   INNER JOIN SYS.ALL_COLUMNS AS B ON A.PARENT_COLUMN_ID = B.COLUMN_ID AND A.PARENT_OBJECT_ID = B.OBJECT_ID
   INNER JOIN SYS.OBJECTS As C ON B.OBJECT_ID = C.OBJECT_ID
WHERE 
    C.IS_MS_SHIPPED = 0
EXCEPT
SELECT 
   OBJECT_NAME(A.OBJECT_ID),
   B.[NAME]
FROM 
   SYS.INDEX_COLUMNS AS A
   INNER JOIN SYS.ALL_COLUMNS B ON A.OBJECT_ID = B.OBJECT_ID AND A.COLUMN_ID = B.COLUMN_ID
   INNER JOIN SYS.OBJECTS  AS C ON  A.OBJECT_ID = C.OBJECT_ID
WHERE 
   A.KEY_ORDINAL = 1
   AND A.IS_INCLUDED_COLUMN = 0
   AND C.IS_MS_SHIPPED = 0

-- start creating indexes on foreign keys
BEGIN
	-- iterate over collection of indexes
	SET @indexCursor = CURSOR FOR
	SELECT [Table], [FK_Column] FROM #TempFKWithoutIndexes;

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
DROP TABLE #TempFKWithoutIndexes;
