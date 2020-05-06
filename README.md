
Agent Installation Scripts for Cimitra
Version: 1.5

Author: Tay Kratzer tay@cimitra.com
**[LINUX]**
**Cimitra Linux Agent Installation in 1 Easy Step**

**1.** **DOWNLOAD AND RUN** the Cimitra Agent for Linux **install** script file on a Linux box in this manner:

**A. NO PROMPT FOR CREDENTIALS**

**[Syntax]**

curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh [cimitra server address] [cimitra server port] [admin user] [admin user password]

**[Example]**

**curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme**

**OR**

**B. DO PROMPT FOR CREDENTIALS**

**[Syntax]**

curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh [cimitra server address] [cimitra server port]

**[Example]**

**curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443**

**ADDITIONAL OPTIONAL PARAMETERS**

Install Agent as a **systemd** process

**[Example]**

**curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme **systemd**

Install Agent and specify the name of the agent with **name=[agent name]**

**[Example]**

**curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme **name=FAVORITE_AGENT**

**[MacOS]**
**Cimitra MacOS Agent Installation in 1 Easy Step**

**1.** **DOWNLOAD AND RUN** the Cimitra Agent for MacOS **install** script file in a Mac terminal session in this manner:

**[Syntax]**

curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_macos_agent_install.sh -o ./ ; chmod +x ./cimitra_macos_agent_install.sh ; ./cimitra_mac_agent_install.sh [cimitra server address] [cimitra server port] [admin user] [admin user password]

**[Example]**

**curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_macos_agent_install.sh -o ./ ; chmod +x ./cimitra_macos_agent_install.sh ; ./cimitra_macos_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme**

**ADDITIONAL OPTIONAL PARAMETERS**

Install Agent and specify the name of the agent with **name=[agent name]**

**[Example]**

curl -H 'Cache-Control: no-cache' -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_macos_agent_install.sh -o ./ ; chmod +x ./cimitra_macos_agent_install.sh ; ./cimitra_macos_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme **name=MY_MAC_BOX**

