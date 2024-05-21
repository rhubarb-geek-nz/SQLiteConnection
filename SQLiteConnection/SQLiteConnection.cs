// Copyright (c) 2024 Roger Brown.
// Licensed under the MIT License.

using System;
using System.Data.Common;
using System.IO;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Runtime.Loader;

namespace RhubarbGeekNz.SQLiteConnection
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
                string hyphen_arch = rid.Substring(rid.LastIndexOf('-'));
                string os;

                if (OperatingSystem.IsWindows())
                {
                    os = "win";
                }
                else
                {
                    if (OperatingSystem.IsAndroid())
                    {
                        os = "linux-bionic";
                    }
                    else
                    {
                        if (OperatingSystem.IsLinux())
                        {
                            if (rid.StartsWith("alpine"))
                            {
                                os = "linux-musl";
                            }
                            else
                            {
                                os = "linux";
                            }
                        }
                        else
                        {
                            if (OperatingSystem.IsMacOS())
                            {
                                os = "osx";
                            }
                            else
                            {
                                if (System.OperatingSystem.IsFreeBSD())
                                {
                                    os = "freebsd";
                                }
                                else
                                {
                                    os = "unix";
                                }
                            }
                        }
                    }
                }

                dir = Path.Combine(dependencyDirPath, os + hyphen_arch);
            }

            this.nativeDependencyDirPath = dir;
        }

        protected override IntPtr LoadUnmanagedDll(string unmanagedDllName)
        {
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
