// Copyright (c) 2024 Roger Brown.
// Licensed under the MIT License.

namespace RhubarbGeekNz.SQLiteConnection.Core
{
    public class SQLiteConnectionFactory
    {
        static public System.Data.Common.DbConnection CreateInstance(string ConnectionString)
        {
            return new Microsoft.Data.Sqlite.SqliteConnection(ConnectionString);
        }
    }
}
