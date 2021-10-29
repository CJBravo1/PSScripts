$ModulePath = $env:PSModulePath
$ModulePath.Split(";") | foreach {copy .\VMWare\ $_ -Recurse -Verbose}
$ModulePath.Split(";") | foreach {copy .\VMware.Hv.Helper\ $_ -Recurse -Verbose}
