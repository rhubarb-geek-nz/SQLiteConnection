#!/usr/bin/env pwsh
# Copyright (c) 2024 Roger Brown.
# Licensed under the MIT License.

param(
	$ConnectionString = 'Data Source=test.db;',
	$CommandText = 'SELECT * FROM MESSAGES'
)

$ErrorActionPreference = "Stop"

trap
{
	throw $PSItem
}

if (-not(Test-Path "test.db"))
{
	@"
CREATE TABLE MESSAGES (CONTENT VARCHAR(256));
INSERT INTO MESSAGES (CONTENT) VALUES ('Hello World');
"@ | & sqlite3 test.db

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}

$Connection = New-SQLiteConnection -ConnectionString $ConnectionString

try
{
	$Connection.Open()

	$Command = $Connection.CreateCommand()

	$Command.CommandText = $CommandText

	$Reader = $Command.ExecuteReader()

	try
	{
		$DataTable = New-Object System.Data.DataTable

		$DataTable.Load($Reader)

		$DataTable | Format-Table
	}
	finally
	{
		$Reader.Dispose()
	}
}
finally
{
	$Connection.Dispose()
}
