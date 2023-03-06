#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
#
#  This file is part of rhubarb-geek-nz/SQLiteConnection.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

param(
	$ConnectionString = "Data Source=test.db;",
	$CommandText = "SELECT * FROM MESSAGES"
)


$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

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

Write-Host $Env:PSModulePath

$Connection = New-SQLiteConnection -ConnectionString $ConnectionString

try
{
	$Connection.Open()

	$Command = $Connection.CreateCommand()

	$Command.CommandText = $CommandText

	$Reader = $Command.ExecuteReader()

	try
	{
		while ($Reader.Read())
		{
			Write-Host $Reader.GetString(0)
		}
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
