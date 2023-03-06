/**************************************************************************
 *
 *  Copyright 2023, Roger Brown
 *
 *  This file is part of rhubarb-geek-nz/SQLiteConnection.
 *
 *  This program is free software: you can redistribute it and/or modify it
 *  under the terms of the GNU Lesser General Public License as published by the
 *  Free Software Foundation, either version 3 of the License, or (at your
 *  option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 */
 
using System.Data.Common;
using System.Management.Automation;

namespace SQLiteConnection
{
    [Cmdlet(VerbsCommon.New,"SQLiteConnection")]
    [OutputType(typeof(DbConnection))]
    public class NewSQLiteConnection : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        public string ConnectionString { get; set; }

        protected override void BeginProcessing()
        {
            WriteVerbose("Begin!");
        }

        protected override void ProcessRecord()
        {
            WriteObject(new System.Data.SQLite.SQLiteConnection(ConnectionString));
        }

        protected override void EndProcessing()
        {
            WriteVerbose("End!");
        }
    }
}
