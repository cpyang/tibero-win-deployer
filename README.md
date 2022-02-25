# tibero-win-deployer
Automate Installation of Tibero Database on Windows (x86-64) Platform  
Run PowerShell with Administrator privilege  

* PS C:\Users\cpyang> __hostname__  
  Login TechNet - https://technet.tmaxsoft.com/en/front/main/main.do  
  Select Demo License Request, request license for _hostname_ from the __hostname__ command 
  Get _license.xml_ from email, and put into installer folder  
* PS C:\Users\cpyang> __Invoke-WebRequest https://github.com/cpyang/tibero-win-install/archive/refs/heads/main.zip -OutFile tibero-win-install.zip__  
* PS C:\Users\cpyang> __Expand-Archive tibero-win-install.zip -DestinationPath .__  
* PS C:\Users\cpyang> __cd tibero-win-install-main__  
* (copy _license.xml_ to this folder)  
* PS C:\Users\cpyang\tibero-win-install-main> __.\install.ps1 -target <installation base directory> [-sid <Tibero SID>]__    
  For Example, to create tibero6 under C:\opt\tibero6 and set SID to mytibero:  
  __.\install.ps1 -target c:\opt -sid mytibero__   

  
```powershell
hostnme
Invoke-WebRequest https://github.com/cpyang/tibero-win-install/archive/refs/heads/main.zip -OutFile tibero-win-deployer.zip  
Expand-Archive tibero-win-deployer.zip -DestinationPath .  
cd tibero-win-deployer-main  
.\install.ps1 -target c:\opt -sid mytibero   
```
