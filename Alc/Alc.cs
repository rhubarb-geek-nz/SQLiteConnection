// Copyright (c) 2024 Roger Brown.
// Licensed under the MIT License.

namespace RhubarbGeekNz.SQLiteConnection
{
    public class SQLiteConnectionFactory
    {
        static public System.Data.Common.DbConnection CreateInstance(string ConnectionString)
        {
            return new System.Data.SQLite.SQLiteConnection(ConnectionString);
        }
    }
}
