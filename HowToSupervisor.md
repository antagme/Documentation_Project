# Supervisor Process Control System

## Why i choose Supervisor

According to how Docker Containers works , we should start only with 1 process. If you only need a _Service_ inside the Container , the best way to configure , is to configure to start with _Service_ Binary the Container so then have the PID 1 this _Service_ to control with _Docker Commands_.
But in my case , i will run more than 1 process in a Container.So i decided to use a process Manager for this work.
According [_Docker_ Official Documentation](https://docs.docker.com/engine/admin/multi-service_container/) , _Supervisor_ is one of the posibilities for this purpose.

## Quick Explanation

Supervisor is a client/server system that allows its users to monitor and control a number of processes on UNIX-like operating systems.
In our situation , we need it for centralize and manage all of the services what are running in a container.
Is necessary to underestand the concept about Container should have one Proccess running in PID 1 and my best candidate was Supervisor.

## How To Configure Supervisor Service 

The first step is Install _Supervisor_ Packet. In Fedora is like:

    dnf install -y supervisor
    
Now need to configure our configuration file, the default ubication of files is `/etc/supervisord.d/`.
We gonna configure this one for a Container , which needs the following services:

- Nslcd
- Zabbix Agent
- Slapd

One important concept about Supervisor is the Service should be run in Foreground. So the Service need to have the option (No fork,Foreground...)

Lets see the file, i comment all the importants parts

```INI
# select if u want supervisord run as Daemon or not
[supervisord]
nodaemon=true

# This configure the unix socket for enable supervisorctl command
# The purpose is control the services individualy or  all of them with a simple command.
# Syntax: supervisorctl start/restart/stop Service name(program:xxxx)/all
[unix_http_server]
file=/var/run/supervisor/supervisor.sock   ; (the path to the socket file)
chmod=0700                       ; socket file mode (default 0700)


# About files path
[supervisord]
logfile=/var/log/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=/var/log/supervisor            ; ('AUTO' child log dir, default $TEMP)

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
; Need also the unix socket defined
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

# Conecting to the socket 
[supervisorctl]
serverurl=unix:///var/run/supervisor/supervisor.sock ; use a unix:// URL  for a unix socket

# Supervisor Also have a web interface for service management ip:9001
[inet_http_server]
port = *:9001

# Nslcd Service Configuration
# I choose --debug instead --nofork because i want to have more log information.
# Also i configure log file path.

[program:nslcd]
command=/usr/sbin/nslcd --debug
redirect_stderr=true
stdout_logfile=/var/log/supervisor/nslcd.log
stderr_logfile=/var/log/supervisor/nslcd.log

# Zabbix Agent Service Configuration
# This one needs to be runned under Zabbix User
# Also i redirect the stdout and error to log file
# startsecs is 3 secs for secure the properly starting of service
[program:agent]
user=zabbix
command = /usr/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf -f
startsecs = 3
redirect_stderr=true
stderr_logfile=/var/log/supervisor/agent.log
stdout_logfile=/var/log/supervisor/agent.log

# Slapd Service Configuration
# The only one option of slapd for foregroud is -d this mean Debug and i set 1 for more information
# When supervisor starts this service will not start cause Autostart=false
# Also if the service fails , supervisor didnt try to start again.
[program:slapd]
command=/sbin/slapd -h "ldap:/// ldapi:/// " -d 1
user=root
autostart=false
autorestart=false
redirect_stderr=true
stdout_logfile=/var/log/supervisor/slapd.log
stderr_logfile=/var/log/supervisor/slapd.log
```




