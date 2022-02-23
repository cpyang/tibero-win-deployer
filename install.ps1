
# if ($args.Length -eq 0) { write-host "help" } 
param (
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	# [string]$server=$(throw "-server <server_hostname_or_ip> is mandatory, please provide a value."),
	$target = $(throw "-target <install_path> is mandatory, please provide a value. Such as C:\opt, tibero6 folder will be created under the directory."),
	$dsn = "tibero",
	$sid = "tibero",
	$port = 8629,
	$user = "tibero",
	$pass = "tmax"
)

# If ("32","64" -NotContains $bit) { Throw “-bit $($bit) is not valid. Please use -bit 32 or -bit 64” } 

# if ($32bit -eq $true) {$bit = "32"}
# write-host "<-target install_path>" $target
write-host "<-server tibero_server_hostname_or_ip>" $server
write-host "[-dsn System_DSN]" $dsn
write-host "[-sid Tibero_SID]" $sid
write-host "[-port Tibero_Port]" $port
write-host "[-user Tibero_username]" $user
write-host "[-pass Tibero_password]" $pass
write-host "[-bit 32/64]" $bit

# Download Installation Package
$source = 'http://cpyang.org/t/tibero6.zip'
$file = 'tibero6.zip'
$Env:TB_SID = $sid
#If the file does not exist, download it from web.
if (-not(Test-Path -Path $file -PathType Leaf)) {
	try {
		Invoke-WebRequest -Uri $source -OutFile $file
		Write-Host "The file [$file] has been downloaded."
	} catch {
		throw $_.Exception.Message
	}
} else {
	Write-Host "Using existing [$file] for installation."
}
$TB_HOME = $target + "\tibero6"

if (-not(Test-Path -Path $TB_HOME)) {
	Expand-Archive -DestinationPath $target $file
} else {
	Write-Host "[$TB_HOME] already exists."
	# Exit 1
}

$path = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
$newpath = $path + ";" + $TB_HOME + "\bin;" + $TB_HOME + "\client\bin"
[Environment]::SetEnvironmentVariable('PATH', $newpath, 'Machine')
[Environment]::SetEnvironmentVariable('TB_HOME', $TB_HOME, 'Machine')
[Environment]::SetEnvironmentVariable('TB_SID', $sid, 'Machine')
[Environment]::SetEnvironmentVariable('TB_NLS_LANG', 'UTF8', 'Machine')

$license = 'license.xml'
if (-not(Test-Path -Path $license -PathType Leaf)) {
	Copy-Item -Destination C:\opt\tibero6\license $license
} else {
	Write-Host "License file [$license] not found."
	Exit 1
}
$server = 'localhost'
foreach ($bit in '32','64') {
	Write-Host "Setting up [$bit]-bit ODBC Driver and DSN." 

	# Prepare Registry File
	(Get-Content -path "Tibero_ODBC$($bit).reg" -Raw) | Foreach-Object {
	    $_ -replace 'C:\\\\opt', ($target -replace '\\','\\') `
	       -replace 'tibero_dsn', $dsn `
	       -replace 'tibero_sid', $sid `
	       -replace 'tibero_username', $user `
	       -replace 'tibero_password', $pass `
	       -replace 'tibero_server', $server `
	       -replace '8629', $port `
	    } | Set-Content -Path Tibero_ODBC_Install.reg

	# Import Modified Registry File
	reg import .\Tibero_ODBC_Install.reg
}
