$configFiles = Get-ChildItem . *_USRP.txt -rec
foreach ($file in $configFiles)
{
    (Get-Content $file.PSPath) |
	? {$_.trim() -ne ""} |
    Foreach-Object { $_ -replace ",", "." -replace "\s+", ","} |
    Set-Content $file.PSPath
}
