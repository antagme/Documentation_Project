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
If you preffer to use an Automated Builds , can take the script i created for this.[HERE](https://github.com/antagme/Documentation_Project/blob/master/AutomatedScript/start_example3.sh)

### Configure
#### Enable Database Monitor in LDAP server

In our others examples we didnt enabled _Monitor Database_ option but now we gonna activate for obtain graphs of the LDAP Operations.

Its a simple 

#### Configure Crond for execute Python Script
#### Configure Zabbix Agentd with PSK
#### Configure Template for Trap LDAP Monitor Information
#### Configure all for get graphs in Zabbix

## Bibliography

- [authconfig Documentation from Red Hat](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System-Level_Authentication_Guide/authconfig-install.html)
- [Fedora Documentation for SSSD Configuration](https://docs.fedoraproject.org/en-US/Fedora/14/html/Deployment_Guide/chap-SSSD_User_Guide-Introduction.html)
- [Mastering Ldap - Matt Butcher](https://www.packtpub.com/networking-and-servers/mastering-openldap-configuring-securing-and-integrating-directory-services)
