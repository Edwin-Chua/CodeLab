@echo off
rem Rebuilds the CodeLab database in App_Data\Database.mdf: runs DropAllTables.sql, Schema.sql
rem and DemoData.sql, in that order. A missing Database.mdf is created first.
rem It asks before deleting anything; run "SetupDatabase.cmd /y" to skip the question.
rem Requires sqlcmd on the PATH.
setlocal

set "DATA_DIR=%~dp0"
set "SERVER=(LocalDB)\MSSQLLocalDB"
set "DB=CodeLabSetup"
set "MDF=%DATA_DIR%Database.mdf"

rem The paths are written into SQL text, so double any ' in a folder name
set "MDF_SQL=%MDF:'=''%"
set "DIR_SQL=%DATA_DIR:'=''%"

if /i "%~1"=="/y" goto :start
echo This deletes every table and all data in "%MDF%"
echo and rebuilds it from Schema.sql and DemoData.sql.
choice /m "Continue"
if errorlevel 2 exit /b 1

:start
rem The site attaches Database.mdf to LocalDB under its file path. Detach it, closing the site's
rem connections, so this script can attach the file under its own name. It stops if a CodeLabSetup
rem database from another folder is attached, so it never empties another copy of CodeLab.
sqlcmd -S "%SERVER%" -b -Q "IF EXISTS (SELECT 1 FROM sys.master_files WHERE database_id = DB_ID(N'%DB%') AND type = 0 AND physical_name <> N'%MDF_SQL%') THROW 50001, 'A %DB% database from another folder is attached to LocalDB. Detach it, then run this again.', 1; DECLARE @Name SYSNAME = (SELECT TOP 1 DB_NAME(database_id) FROM sys.master_files WHERE physical_name = N'%MDF_SQL%'); IF @Name IS NOT NULL AND @Name <> N'%DB%' BEGIN DECLARE @Sql NVARCHAR(400) = N'ALTER DATABASE ' + QUOTENAME(@Name) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE'; BEGIN TRY EXEC (@Sql); END TRY BEGIN CATCH END CATCH; BEGIN TRY EXEC sp_detach_db @dbname = @Name; END TRY BEGIN CATCH SET @Sql = N'DROP DATABASE ' + QUOTENAME(@Name); EXEC (@Sql); END CATCH; END"
if errorlevel 1 goto :fail

if not exist "%MDF%" goto :create

rem Attach the existing file, unless an earlier run that failed left it attached
sqlcmd -S "%SERVER%" -b -Q "IF DB_ID(N'%DB%') IS NULL CREATE DATABASE [%DB%] ON (FILENAME = N'%MDF_SQL%') FOR ATTACH;"
if errorlevel 1 goto :fail
goto :build

:create
sqlcmd -S "%SERVER%" -b -Q "CREATE DATABASE [%DB%] ON (NAME = CodeLab, FILENAME = N'%MDF_SQL%') LOG ON (NAME = CodeLab_log, FILENAME = N'%DIR_SQL%Database_log.ldf')"
if errorlevel 1 goto :fail

:build
sqlcmd -S "%SERVER%" -b -d "%DB%" -i "%DATA_DIR%DropAllTables.sql"
if errorlevel 1 goto :fail

sqlcmd -S "%SERVER%" -b -d "%DB%" -i "%DATA_DIR%Schema.sql"
if errorlevel 1 goto :fail

sqlcmd -S "%SERVER%" -b -d "%DB%" -i "%DATA_DIR%DemoData.sql"
if errorlevel 1 goto :fail

rem Detach so the site can attach the file through its own connection string
sqlcmd -S "%SERVER%" -b -Q "ALTER DATABASE [%DB%] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; EXEC sp_detach_db '%DB%';"
if errorlevel 1 goto :fail

echo Database rebuilt: "%MDF%"
exit /b 0

:fail
rem Leave the file detached, so the site and the next run can still open it
sqlcmd -S "%SERVER%" -Q "IF DB_ID(N'%DB%') IS NOT NULL BEGIN ALTER DATABASE [%DB%] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; EXEC sp_detach_db N'%DB%'; END" >nul 2>&1
echo Database setup failed. See the error above.
exit /b 1
