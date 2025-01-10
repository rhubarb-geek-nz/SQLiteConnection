// Copyright (c) 2024 Roger Brown.
// Licensed under the MIT License.

using System;
using System.Data.Common;
using System.IO;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Runtime.Loader;
using System.Text.Json;

namespace RhubarbGeekNz.SQLiteConnection.Core
{
    [Cmdlet(VerbsCommon.New, "SQLiteConnection")]
    [OutputType(typeof(DbConnection))]
    public class NewSQLiteConnection : PSCmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true)]
        public string ConnectionString { get; set; }

        protected override void ProcessRecord()
        {
            WriteObject(SQLiteConnectionFactory.CreateInstance(ConnectionString));
        }
    }

    internal class AlcModuleAssemblyLoadContext : AssemblyLoadContext
    {
        private readonly string dependencyDirPath, nativeDependencyDirPath;

        public AlcModuleAssemblyLoadContext(string dependencyDirPath)
        {
            this.dependencyDirPath = dependencyDirPath;
            string rid = RuntimeInformation.RuntimeIdentifier;
            string dir = Path.Combine(this.dependencyDirPath, rid);

            if (!Directory.Exists(dir))
            {
                char dsc = Path.DirectorySeparatorChar;
                bool found = false;

                try
                {
                    var exe = Assembly.GetEntryAssembly().Location;
                    int dot = exe.LastIndexOf('.');
                    int slash = exe.LastIndexOf(dsc);

                    if (dot > slash)
                    {
                        exe = exe.Substring(0, dot);
                    }

                    string exeJson = exe + ".deps.json";

                    using (var stream = File.OpenRead(exeJson))
                    {
                        var doc = JsonDocument.Parse(stream);

                        if (doc.RootElement.TryGetProperty("runtimes", out var runtimes))
                        {
                            if (runtimes.TryGetProperty(rid, out var runtimeList))
                            {
                                foreach (var runtime in runtimeList.EnumerateArray())
                                {
                                    dir = Path.Combine(dependencyDirPath, runtime.ToString());

                                    found = Directory.Exists(dir);

                                    if (found)
                                    {
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                catch (FileNotFoundException)
                {
                }

                if (!found)
                {
                    var exe = typeof(string).Assembly.Location;
                    var path = exe.Split(dsc);
                    int i = path.Length - 1;

                    while (i > 0)
                    {
                        string file = path[--i];
                        path[path.Length - 1] = file + ".deps.json";
                        file = string.Join(dsc, path);

                        try
                        {
                            using (var stream = File.OpenRead(file))
                            {
                                var doc = JsonDocument.Parse(stream);

                                if (doc.RootElement.TryGetProperty("runtimes", out var runtimes))
                                {
                                    if (runtimes.TryGetProperty(rid, out var runtimeList))
                                    {
                                        foreach (var runtime in runtimeList.EnumerateArray())
                                        {
                                            dir = Path.Combine(dependencyDirPath, runtime.ToString());

                                            found = Directory.Exists(dir);

                                            if (found)
                                            {
                                                break;
                                            }
                                        }
                                    }
                                }
                            }

                            break;
                        }
                        catch (FileNotFoundException)
                        {
                        }
                    }
                }
            }

            this.nativeDependencyDirPath = dir;
        }

        protected override IntPtr LoadUnmanagedDll(string unmanagedDllName)
        {
            unmanagedDllName = OperatingSystem.IsWindows() ? unmanagedDllName + ".dll" : OperatingSystem.IsMacOS() ? $"lib{unmanagedDllName}.dylib" : $"lib{unmanagedDllName}.so";

            string nativeAssemblyPath = Path.Combine(
                    nativeDependencyDirPath,
                    unmanagedDllName);

            if (File.Exists(nativeAssemblyPath))
            {
                return NativeLibrary.Load(nativeAssemblyPath);
            }

            return IntPtr.Zero;
        }

        protected override Assembly Load(AssemblyName assemblyName)
        {
            string dllName = assemblyName.Name + ".dll";

            string assemblyPath = Path.Combine(
                dependencyDirPath,
                dllName);

            if (File.Exists(assemblyPath))
            {
                return LoadFromAssemblyPath(assemblyPath);
            }

            return null;
        }
    }

    public class AlcModuleResolveEventHandler : IModuleAssemblyInitializer, IModuleAssemblyCleanup
    {
        private static readonly string dependencyDirPath;

        private static readonly AlcModuleAssemblyLoadContext dependencyAlc;

        private static readonly Version alcVersion;

        private static readonly string alcName;

        static AlcModuleResolveEventHandler()
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            dependencyDirPath = Path.GetFullPath(Path.Combine(Path.GetDirectoryName(assembly.Location), "lib"));
            dependencyAlc = new AlcModuleAssemblyLoadContext(dependencyDirPath);
            AssemblyName name = assembly.GetName();
            alcVersion = name.Version;
            alcName = name.Name + ".Alc";
        }

        public void OnImport()
        {
            AssemblyLoadContext.Default.Resolving += ResolveAlcModule;
        }

        public void OnRemove(PSModuleInfo psModuleInfo)
        {
            AssemblyLoadContext.Default.Resolving -= ResolveAlcModule;
        }

        private static Assembly ResolveAlcModule(AssemblyLoadContext defaultAlc, AssemblyName assemblyToResolve)
        {
            if (alcName.Equals(assemblyToResolve.Name) && alcVersion.Equals(assemblyToResolve.Version))
            {
                return dependencyAlc.LoadFromAssemblyName(assemblyToResolve);
            }

            return null;
        }
    }
}
