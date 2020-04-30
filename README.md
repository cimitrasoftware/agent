
GroupWise Admin Helpdesk Scripts by Cimitra
Version: 1.5

Author: Tay Kratzer tay@cimitra.com

**Cimitra Linux Agent Installation in 1 Easy Step**

**1.** **DOWNLOAD AND RUN** the Cimitra Agent for Linux **install** script file on a Linux box in this manner:

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh [cimitra server address] [cimitra server port] [admin user] [admin user password]

**curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme**

**ADDITIONAL OPTIONAL PARAMETERS**

Install Agent as a **systemd** process

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme **systemd**

Install Agent and specify the name of the agent with **name=[agent name]**

curl -LJO https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra_linux_agent_install.sh -o ./ ; chmod +x ./cimitra_linux_agent_install.sh ; ./cimitra_linux_agent_install.sh cimitra.example.com 443 admin@cimitra.com changeme **name=FAVORITE_AGENT**
