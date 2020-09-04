
Author: Tay Kratzer tay@cimitra.com

Windows Agent Installation Script for Windows
Version: 1.0

**Cimitra Windows Agent Installation in 1 Easy Step**

**NOTE: The PowerShell script must be run on PowerShell 6 or greater. **

**1.** **DOWNLOAD AND RUN** the Cimitra Agent for Windows **install** script file in a terminal session. Copy the entire line which should make mention to the cimitra_agent_install.sh three times. 

**A. NO PROMPT FOR CREDENTIALS**

**[Syntax]**

iwr https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.ps1 -OutFile .\cimitra_agent_install.ps1  ; .\cimitra_agent_install.ps1 [cimitra server address] [cimitra server port] [admin user] [admin user password]

**[Example]**

iwr https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.ps1 -OutFile .\cimitra_agent_install.ps1  ; .\cimitra_agent_install.ps1 192.168.1.16 443 admin@cimitra.com changeme

**- OR -**

**B. DO PROMPT FOR CREDENTIALS**

**[Syntax]**

iwr https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.ps1 -OutFile .\cimitra_agent_install.ps1  ; .\cimitra_agent_install.ps1 [cimitra server address] [cimitra server port]

**[Example]**

iwr https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.ps1 -OutFile .\cimitra_agent_install.ps1  ; .\cimitra_agent_install.ps1 192.168.1.16 443 

**ADDITIONAL OPTIONAL PARAMETERS**

( Reinstall Agent )

**[Example]**

iwr https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.ps1 -OutFile .\cimitra_agent_install.ps1  ; .\cimitra_agent_install.ps1 192.168.1.16 443 admin@cimitra.com changeme **reinstall**

( Install Windows Agent and specify the name of the agent with **name=[agent name]** )

**[Example]**

iwr https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.ps1 -OutFile .\cimitra_agent_install.ps1  ; .\cimitra_agent_install.ps1 192.168.1.16 443 admin@cimitra.com changeme **name=MyFavoriteWindowsBox**

Non-Windows Agent Installation Script for Cimitra
Version: 1.6

**Cimitra Linux/MacOS or Node.js Agent Installation in 1 Easy Step**

**1.** **DOWNLOAD AND RUN** the Cimitra Agent for Linux/MacOS and Node.js platforms (ARM Processors require Node.js) **install** script file in a terminal session. Copy the entire line which should make mention to the cimitra_agent_install.sh three times. 

**A. NO PROMPT FOR CREDENTIALS**

**[Syntax]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.sh -o ./ ; chmod +x ./cimitra_agent_install.sh ; ./cimitra_agent_install.sh [cimitra server address] [cimitra server port] [admin user] [admin user password]

**[Example]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.sh -o ./ ; chmod +x ./cimitra_agent_install.sh ; ./cimitra_agent_install.sh 192.168.1.16 443 admin@cimitra.com changeme

**- OR -**

**B. DO PROMPT FOR CREDENTIALS**

**[Syntax]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.sh -o ./ ; chmod +x ./cimitra_agent_install.sh ; ./cimitra_agent_install.sh [cimitra server address] [cimitra server port]

**[Example]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.sh -o ./ ; chmod +x ./cimitra_agent_install.sh ; ./cimitra_agent_install.sh 192.168.1.16 443

**ADDITIONAL OPTIONAL PARAMETERS**

( Install Agent as a **systemd** process [Linux only] )

**[Example]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.sh.sh -o ./ ; chmod +x ./cimitra_agent_install.sh ; ./cimitra_agent_install.sh 192.168.1.16 443 admin@cimitra.com changeme systemd

( Install Agent and specify the name of the agent with **name=[agent name]** )

**[Example]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_agent_install.sh -o ./ ; chmod +x ./cimitra_agent_install.sh ; ./cimitra_agent_install.sh 192.168.1.16 443 admin@cimitra.com changeme name=FAVORITE_AGENT

