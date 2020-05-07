
Agent Installation Scripts for Cimitra
Version: 1.5

Author: Tay Kratzer tay@cimitra.com
**Cimitra Linux/MacOS Agent Installation in 1 Easy Step**

**1.** **DOWNLOAD AND RUN** the Cimitra Agent for Linux/MacOS **install** script file in a terminal session. Copy the entire line which should make mention to the cimitra_nix_agent_install.sh three times. 

**A. NO PROMPT FOR CREDENTIALS**

**[Syntax]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_nix_agent_install.sh -o ./ ; chmod +x ./cimitra_nix_agent_install.sh ; ./cimitra_nix_agent_install.sh [cimitra server address] [cimitra server port] [admin user] [admin user password]

**[Example]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_nix_agent_install.sh -o ./ ; chmod +x ./cimitra_nix_agent_install.sh ; ./cimitra_nix_agent_install.sh 192.168.1.16 443 admin@cimitra.com changeme

**- OR -**

**B. DO PROMPT FOR CREDENTIALS**

**[Syntax]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_nix_agent_install.sh -o ./ ; chmod +x ./cimitra_nix_agent_install.sh ; ./cimitra_nix_agent_install.sh [cimitra server address] [cimitra server port]

**[Example]**

**curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_nix_agent_install.sh -o ./ ; chmod +x ./cimitra_nix_agent_install.sh.sh ; ./cimitra_nix_agent_install.sh cimitra.example.com 443**

**ADDITIONAL OPTIONAL PARAMETERS**

( Install Agent as a **systemd** process [Linux only] )

**[Example]**

**curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_nix_agent_install.sh.sh -o ./ ; chmod +x ./cimitra_nix_agent_install.sh ; ./cimitra_nix_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme systemd**

( Install Agent and specify the name of the agent with **name=[agent name]** )

**[Example]**

**curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_nix_agent_install.sh -o ./ ; chmod +x ./cimitra_nix_agent_install.sh ; ./cimitra_nix_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme name=FAVORITE_AGENT**

