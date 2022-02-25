# tibero-win-deployer
Automate Installation of Tibero Database on Windows (x86-64) Platform  
Run PowerShell with Administrator privilege  

* PS C:\Users\cpyang> Invoke-WebRequest https://github.com/cpyang/tibero-win-deployer/archive/refs/heads/main.zip -OutFile tibero-win-deployer.zip  
* PS C:\Users\cpyang> Expand-Archive tibero-win-deployer.zip -DestinationPath .  
* PS C:\Users\cpyang> cd tibero-win-deployer-main  
* (Add license.xml)  
  Login TechNet - https://technet.tmaxsoft.com/en/front/main/main.do  
  Select Demo License Request  
  Get _license.xml_ from email, and put into installer folder  
* PS C:\Users\cpyang\tibero-win-deployer-main> .\install.ps1 -target <installation base directory> [-sid <Tibero SID>]    
  For Example, to create tibero6 under C:\opt\tibero6 and set SID to mytibero:  
  .\install.ps1 -target c:\opt -sid mytibero   
