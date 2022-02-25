# tibero-win-deployer
Automate Installation of Tibero Database on Windows (x86-64) Platform  
Run PowerShell with Administrator privilege  

cd tibero-win-deployer    
.\install.ps1 -target <installation base directory> [-sid <Tibero SID>]    

For Example, to create tibero6 under C:\opt\tibero6 and set SID to mytibero:  
.\install.ps1 -target c:\opt -sid mytibero   

