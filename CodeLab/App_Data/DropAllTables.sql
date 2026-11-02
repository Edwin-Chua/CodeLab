-- DANGER: deletes every table and all data in the CURRENT database.
-- SetupDatabase.cmd runs this before Schema.sql and DemoData.sql. You can also run it by hand.
IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 50001, 'Select your CodeLab database first, not a system database.', 1;

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX) = N'';

-- 1. Drop all foreign keys first, so the tables can be dropped in any order
SELECT @sql += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(parent_object_id))
             + N' DROP CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.foreign_keys;
EXEC sys.sp_executesql @sql;

-- 2. Drop every table (their indexes and other constraints go with them)
SET @sql = N'';
SELECT @sql += N'DROP TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.tables;
EXEC sys.sp_executesql @sql;

-- Check: stop here if any table is left
IF EXISTS (SELECT 1 FROM sys.tables)
    THROW 50002, 'Some tables could not be dropped.', 1;
