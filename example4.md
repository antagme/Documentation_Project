# Example 4 - Zabbix Monitoring to Monitor Database from Openldap Server

## Overview

Finally, in this model, we will see in a Zabbix server how to have monitored by graphs, all the operations that are done in our LDAP Server and all connections to it.

_Docker Images_ used for this example:
- [Ldap StartTLS with Crond Python Script](https://hub.docker.com/r/antagme/ldap_zabbix)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos)
- [Client for do some searchs and see the graphs](https://hub.docker.com/r/antagme/client_gssapi)
- [Zabbix with Openldap Custom Template](https://hub.docker.com/r/antagme/httpd/)

### Fast Deployment

I Made this example for show how to configure your _Ldap Server_ , anyway if you only want check how to it works , maybe be interesed in this another explanation.[Automated Build and How it Works](https://github.com/antagme/Documentation_Project/blob/master/example4fast.md)

## Features

- Monitorized LDAP Server 
- Secure PSK Zabbix Agent for multiple information
- Zabbix Pretty Graphs with server information and LDAP information

## Requisites

- [Nslcd and nsswitch file configurated for host retrieving](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md)
- Own Certificates for CA and Server with properly FQDN in Server Certificate.

## Instalation
### Hostnames and our ips

- LDAP Server: ldap.edt.org 172.18.0.2
- Kerberos Server: kserver.edt.org 172.18.0.3
- Client: client.edt.org  172.18.0.8
- Zabbix: zabbix.edt.org  172.18.0.10

### Starting
Starting from the base that we already have an openldap server running without these technologies.

To properly configure the servers and the client, we have to be careful in 3 essential things.

- Need to have working the GSSAPI Auth On _LDAP Server_ , if you dont have it please see [Example 1](https://github.com/antagme/Documentation_Project/blob/master/example1.md)
- Enable Database Monitor in LDAP server
- Configure Zabbix Agentd with PSK
- Configure Crond for execute Python Script
- Configure Template for Trap LDAP Monitor Information
- Import it to Zabbix

In our case for this example we will use some docker containers that I created for the occasion.
In these containers are already made the modifications, are just an example, you can do it on your own server
If you dont want use my examples , go directly to [Configure](#configure).

Note: My Containers can communicate between them , because i configurated ldap for do ip resolution [Here](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md) , if u don't using my containers , you should put all container entries in **/etc/hosts** for each container , like this.

    172.18.0.2 ldap.edt.org
    172.18.0.3 kserver.edt.org
    172.18.0.8 client.edt.org
    172.18.0.10 zabbix.edt.org  
    
#### Create Docker Network

_This is for a very important reason, we need to always have the same container IP for the proper Ip distribution through LDAP and NSLCD.
In the default Bridge Network , we can't assign ips for containers_


 ```bash
 # docker network create --subnet 172.18.0.0/16 -d bridge ldap
 ```
 
#### Run Docker LDAP
 ```bash
 # docker run --name ldap --hostname ldap.edt.org --net ldap --ip 172.18.0.2  --detach antagme/ldap_zabbix
 ```  

#### Run Docker Kerberos (TGT)  
 ```bash
 # docker run --name kerberos --hostname kserver.edt.org --net ldap --ip 172.18.0.3  --detach antagme/kerberos:supervisord
 ```
 
#### Run Docker Client   
 ```bash
 # docker run --name client --hostname client.edt.org --net ldap --ip 172.18.0.8 --detach antagme/client_gssapi
 ```

#### Run Docker Zabbix   
 ```bash
 # docker run --name zabbix --hostname zabbix.edt.org --net ldap --ip 172.18.0.10 --detach antagme/httpd:zabbix
 ```


These dockers containers are not interactive, to access you have to do the following order:

    docker exec --interactive --tty [Docker Name] bash
    
#### Automated Script
If you preffer to use an Automated Builds, can take the [script](https://github.com/antagme/Documentation_Project/blob/master/AutomatedScript/start_example4.sh) i created for this.

### Configure
#### Enable Database Monitor in LDAP server

In our others examples we didnt enabled _Monitor Database_ option but now we gonna activate for obtain graphs of the LDAP Operations.

Its a simple modification in the [slapd](https://raw.githubusercontent.com/antagme/ldap_zabbix/master/files/slapd.conf) configuration, lets see:

    #
    # See slapd.conf(5) for details on configuration options.
    # This file should NOT be world readable.
    #

    include         /etc/openldap/schema/corba.schema
    include         /etc/openldap/schema/core.schema
    include         /etc/openldap/schema/cosine.schema
    include         /etc/openldap/schema/duaconf.schema
    include         /etc/openldap/schema/dyngroup.schema
    include         /etc/openldap/schema/inetorgperson.schema
    include         /etc/openldap/schema/java.schema
    include         /etc/openldap/schema/misc.schema
    include         /etc/openldap/schema/nis.schema
    include         /etc/openldap/schema/openldap.schema
    include         /etc/openldap/schema/ppolicy.schema
    include         /etc/openldap/schema/collective.schema

    # Allow LDAPv2 client connections.  This is NOT the default.
    allow bind_v2

    pidfile         /var/run/openldap/slapd.pid
    #argsfile       /var/run/openldap/slapd.args

    # Limit SASL options to only GSSAPI and not other client-favorites. Apparently there is an issue where
    # clients will default to non-working SASL mechanisms and will make you angry.
    sasl-secprops noanonymous,noplain,noactive

    # SASL connection information. The realm should be your Kerberos realm as configured for the system. The
    # host should be the LEGITIMATE hostname of this server
    sasl-realm EDT.ORG
    sasl-host ldap.edt.org

    # Rewrite certain SASL bind DNs to more readable ones. Otherwise you bind as some crazy default
    # that ends up in a different base than your actual one. This uses regex to rewrite that weird
    # DN and make it become one that you can put within your suffix.
    authz-policy from
    authz-regexp "^uid=[^,/]+/admin,cn=edt\.org,cn=gssapi,cn=auth" "cn=Manager,dc=edt,dc=org"
    authz-regexp "^uid=([^,]+),cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=usuaris,dc=edt,dc=org"
    # ------------------------------------------------------------------------------------------------------------
    # SSL certificate file paths
    TLSCACertificateFile /etc/ssl/certs/cacert.pem
    TLSCertificateFile /etc/openldap/certs/ldapcert.pem
    TLSCertificateKeyFile /etc/openldap/certs/ldapserver.pem
    TLSCipherSuite HIGH:MEDIUM:+SSLv2
    TLSVerifyClient allow
    # -----------------------------------------------

    database hdb
    suffix "dc=edt,dc=org"
    rootdn "cn=Manager,dc=edt,dc=org"
    rootpw {SASL}admin/admin@EDT.ORG
    directory /var/lib/ldap
    index objectClass,cn,memberUid,gidNumber,uidNumber,uid eq,pres

    access to attrs=userPassword
      by self write
      by anonymous auth
      by * none

    access to *
      by peername.ip=172.18.0.0%255.255.0.0 read
      by * read break

    # ------------------------------------------------

    # enable monitoring
    database monitor
    # allow only rootdn to read the monitor
    access to *
           by dn.exact="cn=Monitoring,dc=edt,dc=org" read
           by * none

We will only look at the last part, its for enable Database Monitor for later catch data and send it to zabbix.

    # enable monitoring
    database monitor
    # allow only rootdn to read the monitor
    access to *
           by dn.exact="cn=Monitoring,dc=edt,dc=org" read
           by * none

We only need to write `database monitor` for enable and we'll need too define the acl of this database, i created for the ocasion a new entry for only _Monitoring_, my entry is like this, the reason is fore securely Monitoring.

    dn: cn=Monitoring,dc=edt,dc=org
    objectClass: top
    objectClass: person
    objectClass: organizationalPerson
    cn: Monitoring
    sn: Monitoring
    userPassword: {SHA}ovf8ta/reYP/u2zj0afpHt8yE1A=

And in my ACL i authorize only read by this DN.

    access to *
           by dn.exact="cn=Monitoring,dc=edt,dc=org" read
           by * none

Now load this configuration and you have enabled the Database.

#### Configure Crond for execute Python Script

I found a Python script in a Github repository, this alone is useless, but i decided to work in this, and i modified for my own use, later we gonna check the creation of _Template for Zabbix_

The [script](https://raw.githubusercontent.com/antagme/ldap_zabbix/master/scripts/ldapstats.py) is a simple generation of  _JSON_ data and send it to _Zabbix_

Note:_This is a modified script based on https://github.com/bergzand/zabbix-ldap-ops/blob/master/ldapstats.py_

When i decided to _Monitoring_ LDAP Monitor Database with graphs, i searched for the alternatives i had for perform this properly and i chose do with a _Python_ script and _Crond_ for executing this each minute, the problem was how i can do Crond inside a Container, so lets see this.

When i generate the image, inside the _build_, i create the crontab on the fly, with this simply command.

```Dockerfile
RUN chmod +x /scripts/ldapstats.py & crontab -l | { cat; echo "* * * * * /scripts/ldapstats.py";} | crontab -
```

With this command we give permisions to the script, and later create the crontab on the same line.

This crontab will not execute cause in _Container_ Crond is disabled, i configured an entry on [_Supervisord_](https://github.com/antagme/Documentation_Project/blob/master/HowToSupervisor.md) for this. 

```INI
[program:crond]
user=root
command = crond -x proc
redirect_stderr=true
stderr_logfile=/var/log/supervisor/crond.log
stdout_logfile=/var/log/supervisor/crond.log
```

Now we have our script executing each minute for sending data to Zabbix.

#### Configure Zabbix Agentd with PSK

For have Zabbix Agent packet installed you should `dnf install -y zabbix-agent`
Now we gonna a configure the Agent for Secure transmision using a _Pre-shared Key_, its a simple operation.

First we gonna create the key. We gonna use _Openssl_

    openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk

Now we gonna configure [`/etc/zabbix/zabbix_agentd.conf`](https://raw.githubusercontent.com/antagme/ldap_zabbix/master/files/zabbix_agentd.conf)

    # This is a configuration file for Zabbix agent daemon (Unix)
    # To get more information about Zabbix, visit http://www.zabbix.com

    ############ GENERAL PARAMETERS #################

    ### Option: PidFile
    #	Name of PID file.
    #
    # Mandatory: no
    # Default:
    # PidFile=/tmp/zabbix_agentd.pid
    PidFile=/run/zabbix/zabbix_agentd.pid

    ### Option: LogFile
    #	Log file name for LogType 'file' parameter.
    #
    # Mandatory: no
    # Default:
    # LogFile=

    LogFile=/var/log/zabbix/zabbix_agentd.log

    ### Option: LogFileSize
    #	Maximum size of log file in MB.
    #	0 - disable automatic log rotation.
    #
    # Mandatory: no
    # Range: 0-1024
    # Default:
    # LogFileSize=1
    LogFileSize=0

    ##### Passive checks related

    ### Option: Server
    #	List of comma delimited IP addresses (or hostnames) of Zabbix servers.
    #	Incoming connections will be accepted only from the hosts listed here.
    #	If IPv6 support is enabled then '127.0.0.1', '::127.0.0.1', '::ffff:127.0.0.1' are treated equally.
    #
    # Mandatory: no
    # Default:
    # Server=

    Server=172.18.0.10

    ### Option: ListenIP
    #	List of comma delimited IP addresses that the agent should listen on.
    #	First IP address is sent to Zabbix server if connecting to it to retrieve list of active checks.
    #
    # Mandatory: no
    # Default:
    ListenIP=0.0.0.0

    ##### Active checks related

    ### Option: ServerActive
    #	List of comma delimited IP:port (or hostname:port) pairs of Zabbix servers for active checks.
    #	If port is not specified, default port is used.
    #	IPv6 addresses must be enclosed in square brackets if port for that host is specified.
    #	If port is not specified, square brackets for IPv6 addresses are optional.
    #	If this parameter is not specified, active checks are disabled.
    #	Example: ServerActive=127.0.0.1:20051,zabbix.domain,[::1]:30051,::1,[12fc::1]
    #
    # Mandatory: no
    # Default:
    # ServerActive=

    #ServerActive=172.18.0.2

    ### Option: Hostname
    #	Unique, case sensitive hostname.
    #	Required for active checks and must match hostname as configured on the server.
    #	Value is acquired from HostnameItem if undefined.
    #
    # Mandatory: no
    # Default:
    # Hostname=

    Hostname=Zabbix LDAP

    ### Option: AllowRoot
    #	Allow the agent to run as 'root'. If disabled and the agent is started by 'root', the agent
    #	will try to switch to the user specified by the User configuration option instead.
    #	Has no effect if started under a regular user.
    #	0 - do not allow
    #	1 - allow
    #
    # Mandatory: no
    # Default:
    AllowRoot=1

    ####### TLS-RELATED PARAMETERS #######

    ### Option: TLSConnect
    #	How the agent should connect to server or proxy. Used for active checks.
    #	Only one value can be specified:
    #		unencrypted - connect without encryption
    #		psk         - connect using TLS and a pre-shared key
    #		cert        - connect using TLS and a certificate
    #
    # Mandatory: yes, if TLS certificate or PSK parameters are defined (even for 'unencrypted' connection)
    # Default:
    TLSConnect=psk

    ### Option: TLSAccept
    #	What incoming connections to accept.
    #	Multiple values can be specified, separated by comma:
    #		unencrypted - accept connections without encryption
    #		psk         - accept connections secured with TLS and a pre-shared key
    #		cert        - accept connections secured with TLS and a certificate
    #
    # Mandatory: yes, if TLS certificate or PSK parameters are defined (even for 'unencrypted' connection)
    # Default:
    TLSAccept=psk


    ### Option: TLSPSKIdentity
    #	Unique, case sensitive string used to identify the pre-shared key.
    #
    # Mandatory: no
    # Default:
    TLSPSKIdentity=PSK 001

    ### Option: TLSPSKFile
    #	Full pathname of a file containing the pre-shared key.
    #
    # Mandatory: no
    # Default:
    TLSPSKFile=/etc/zabbix/zabbix_agentd.psk

The importants parts is this:
<pre><code>
    TLSConnect=psk <b>Enable TLS connection by PSK</b>
    TLSAccept=psk <b>Accept TLS connection by PSK</b>
    TLSPSKFile=/home/zabbix/zabbix_agentd.psk <b>Absolute route to PSK file</b>
    TLSPSKIdentity=PSK 001 <b>The id of PSK each agent should be different number</b>
</code></pre>

Later we gonna configure it on Zabbix Frontend page.

#### Configure Template for Trap LDAP Monitor Information

We have a _Script_ but in Zabbix for Graphs, we need a template for get the data and drawn the graph.
I found a nice one in a Github, i catch the idea and i create my own [template](https://github.com/antagme/httpd/blob/master/Template%20OpenLDAP.xml).
Note:_The script doesnt work if you dont properly configurated a template!!!_

#### Configure all for get graphs in Zabbix

Having the Agentd working with PSK, the LDAP Monitor enabled, the Croned Python script sending data, we need now configure frontend of Zabbix for finish this journey.

Assuming you have a Zabbix server working, if you dont please check the [Official Tutorial of Zabbix Server installation](https://www.zabbix.com/documentation/3.4/manual/installation/install)



## Bibliography

- [authconfig Documentation from Red Hat](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System-Level_Authentication_Guide/authconfig-install.html)
- [Fedora Documentation for SSSD Configuration](https://docs.fedoraproject.org/en-US/Fedora/14/html/Deployment_Guide/chap-SSSD_User_Guide-Introduction.html)
- [Mastering Ldap - Matt Butcher](https://www.packtpub.com/networking-and-servers/mastering-openldap-configuring-securing-and-integrating-directory-services)
