
# if ($args.Length -eq 0) { write-host "help" } 
param (
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	$target = $(throw "-target <install_path> is mandatory, please provide a value. Such as C:\opt, tibero6 folder will be created under the directory."),
	$dsn = "tibero",
	$sid = "tibero",
	$port = 8629,
	$user = "tibero",
	$pass = "tmax"
)

Function global:ADD-PATH() {
	[Cmdletbinding()]
	param
	(
		[parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0)]
		[String[]]$addedFolder
	)

	# Get the current search path from the environment keys in the registry.
	#$oldPath=(Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINESystemCurrentControlSetControlSession ManagerEnvironment -Name PATH).Path
	$oldPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')

	# See if a new folder has been supplied.
	IF (!$addedFolder)
		{ Return "No Folder Supplied. $ENV:PATH Unchanged"}

	# See if the new folder exists on the file system.
	IF (!(TEST-PATH $addedFolder))
		{ Return "Folder Does not Exist, Cannot be added to $ENV:PATH" }

	# See if the new Folder is already in the path.
	IF ($oldPath | Select-String -SimpleMatch $addedFolder)
		{ Return "Folder already within $ENV:PATH" }

	# Set the New Path
	$newPath=$oldPath+";"+$addedFolder

	#Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINESystemCurrentControlSetControlSession ManagerEnvironment -Name PATH Value $newPath
	[Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')

	# Sort and remove duplicate items from path
	[Environment]::SetEnvironmentVariable('Path',(([Environment]::GetEnvironmentVariable('Path','Machine') -split ';'|Sort-Object -Unique) -join ';'),'Machine')
	# Show our results back to the world
	Return $newPath
}

Function global:GET-PATH() { Return $ENV:PATH }

Function global:REMOVE-PATH() {
	[Cmdletbinding()]
	param
	(
		[parameter(Mandatory=$True, ValueFromPipeline=$True, Position=0)]
		[String[]]$RemovedFolder
	)

	# Get the Current Search Path from the environment keys in the registry
	#$NewPath=(Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINESystemCurrentControlSetControlSession ManagerEnvironment -Name PATH).Path
	$newPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')

	# Find the value to remove, replace it with $NULL. If its not found, nothing will change.
	$newPath=$newPath.replace($RemovedFolder,$NULL)

	# Update the Environment Path
	#Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINESystemCurrentControlSetControlSession ManagerEnvironment -Name PATH Value $newPath
	[Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')

	# Show what we just did
	Return $newPath
} 

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

ADD-PATH($TB_HOME + "\bin")
ADD-PATH($TB_HOME + "\client\bin")
[Environment]::SetEnvironmentVariable('TB_HOME', $TB_HOME, 'Machine')
[Environment]::SetEnvironmentVariable('TB_SID', $sid, 'Machine')
[Environment]::SetEnvironmentVariable('TB_NLS_LANG', 'UTF8', 'Machine')
[Environment]::SetEnvironmentVariable('TB_HOME', $TB_HOME)
[Environment]::SetEnvironmentVariable('TB_SID', $sid)
[Environment]::SetEnvironmentVariable('TB_NLS_LANG', 'UTF8')

$license = 'license.xml'
if (Test-Path -Path $license -PathType Leaf) {
	Copy-Item -Destination C:\opt\tibero6\license $license
} else {
	Write-Host "License file [$license] not found."
	Exit 1
}
$server = 'localhost'
foreach ($bit in '32') {
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

cd $TB_HOME\bin
cscript .\tbinstall.vbs $TB_HOME $sid
cd $TB_HOME\config
Start-Process -FilePath ".\gen_tip.bat" -Wait -NoNewWindow
tbboot nomount
echo @"
create database "$sid" 
  user sys identified by tibero 
  maxinstances 8 
  maxdatafiles 100 
  character set UTF8
  national character set UTF16 
  logfile 
    group 1 'log001.log' size 100M, 
    group 2 'log002.log' size 100M, 
    group 3 'log003.log' size 100M 
  maxloggroups 255 
  maxlogmembers 8 
  noarchivelog 
    datafile 'system001.dtf' size 100M autoextend on next 100M maxsize unlimited 
    default temporary tablespace TEMP 
      tempfile 'temp001.dtf' size 100M autoextend on next 100M maxsize unlimited 
      extent management local autoallocate 
    undo tablespace UNDO 
      datafile 'undo001.dtf' size 100M autoextend on next 100M maxsize unlimited 
      extent management local autoallocate;
quit;
"@ | tbsql sys/tibero
tbdown
tbboot
cd $TB_HOME\scripts
cscript .\system.vbs -p1 tibero -p2 tibero -a1 Y -a2 Y -a3 Y -a4 Y
#tbdown
#cscript .\tbuninstall.vbs
