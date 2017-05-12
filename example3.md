# Example 3 - Client with PAM + SSSD for Kerberos Auth , LDAP user information and Kerberos Password

## Overview

In this model, starting from example one, we will see how to make a more secure authentication in the system using the best of Kerberos and Ldap technologies.

For this example, in the Client we will see how the System-Auth works with these two technologies, and we will perform a series of checks to make sure it works correctly.

_Docker Images_ used for this example:
- [Ldap StartTLS + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_sssd)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client PAM + ldapwhoami](https://hub.docker.com/r/antagme/client/)


### Fast Deployment

I Made this example for show how to configure your _Ldap Server_ , anyway if you only want check how to it works , maybe be interesed in this another explanation.[Automated Build and How it Works](https://github.com/antagme/Documentation_Project/blob/master/example1fast.md)

## Features

- Openldap Server for use to backup user information
- Secure GSSAPI Authentification for LDAP client utilities
- Secure connection between client and server using StartTLS
- Fastest operations with LDAP Client Utilities
- Secure authentification through Kerberos

## Requisites

- [Nslcd and nsswitch file configurated for host retrieving](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md)
- Own Certificates for CA and Server with properly FQDN in Server Certificate.

## Instalation
### Hostnames and our ips

- LDAP Server: ldap.edt.org 172.18.0.2
- Kerberos Server: kserver.edt.org 172.18.0.3
- Client: client.edt.org  172.18.0.8

### Starting
Starting from the base that we already have an openldap server running without these technologies.

To properly configure the servers and the client, we have to be careful in 3 essential things.

- Need to have working the GSSAPI Auth On _LDAP Server_ , if you dont have it please see [Example 1](https://github.com/antagme/Documentation_Project/blob/master/example1.md)
- Configure sssd service for _Kerberos Auth_ , _Take information from LDAP_, and _finally use kerberos password instead ldap_
- Configure auth-config for enable sssd Service
- Check if Pam is properly configured
- Try in client to login with an user with principal created and another one without

In our case for this example we will use some docker containers that I created for the occasion.
In these containers are already made the modifications, are just an example, you can do it on your own server
If you dont want use my examples , go directly to [Configure](#configure).

Note: My Containers can communicate between them , because i configurated ldap for do ip resolution [Here](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md) , if u don't using my containers , you should put all container entries in **/etc/hosts** for each container , like this.

    172.18.0.2 ldap.edt.org
    172.18.0.3 kserver.edt.org
    172.18.0.8 client.edt.org

#### Create Docker Network

_This is for a very important reason, we need to always have the same container IP for the proper Ip distribution through LDAP and NSLCD.
In the default Bridge Network , we can't assign ips for containers_


 ```bash
 # docker network create --subnet 172.18.0.0/16 -d bridge ldap
 ```
 
#### Run Docker LDAP
 ```bash
 # docker run --name ldap --hostname ldap.edt.org --net ldap --ip 172.18.0.2  --detach antagme/ldap_sssd
 ```  

#### Run Docker Kerberos (TGT)  
 ```bash
 # docker run --name kerberos --hostname kserver.edt.org --net ldap --ip 172.18.0.3  --detach antagme/kerberos:supervisord
 ```
 
#### Run Docker Client   
 ```bash
 # docker run --name client --hostname client.edt.org --net ldap --ip 172.18.0.8 --detach antagme/client:pam_tls
 ```

These dockers containers are not interactive, to access you have to do the following order:

    docker exec --interactive --tty [Docker Name] bash
    
#### Automated Script
If you preffer to use an Automated Builds , can take the script i created for this.[HERE](https://github.com/antagme/Documentation_Project/blob/master/AutomatedScript/start_example3.sh)

### Configure
#### Configure sssd service for Kerberos Auth , Take information from LDAP, and finally use kerberos password instead ldap

We gonna configure the [sssd](https://fedoraproject.org/wiki/Features/SSSD) , the official daemon offered by Fedora for Control Authentification in the System and configure the Backends and use it in authconfig.

The first step you need is install the _Packets of SSSD_ with this command: `dnf install -y sssd sssd-client authconfig`
Note:_You should install authconfig packet too for configure system-auth_

Installed this , we gonna configure the [sssd.conf](https://raw.githubusercontent.com/antagme/client/master/files/sssd.conf) file.
The key parts is configure our kerberos and ldap servers for the properly authentification to system.

Lets see the file:

```
[sssd]
config_file_version = 2
domains = default
services = pam, nss 

[domain/default]
id_provider = ldap
ldap_uri = ldap://172.18.0.2
ldap_search_base = dc=edt,dc=org
auth_provider = krb5
chpass_provider = krb5
krb5_realm = EDT.ORG
krb5_server = 172.18.0.3
krb5_kpasswd = 172.18.0.3
cache_credentials = True
krb5_store_password_if_offline = True

[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3

[pam]
reconnection_retries = 3
offline_credentials_expiration = 2
offline_failed_login_attempts = 3
offline_failed_login_delay = 5
```

This is my configuration , maybe this can be better , anyway sssd is a pussy daemon.
Now , we gonna profundize through the key parts.

- **[domain/default]**
    - `id_provider = ldap `  Define what is our id provider. (if the entry doesnt exist on ldap , can't enter to the system)
    - `ldap_uri = ldap://172.18.0.2` Our ldap uri (Some problem on Docker with DNS i resolve this putting Ip instead FQDN)
    - `ldap_search_base = dc=edt,dc=org` Base of the LDAP Backend
    - `auth_provider = krb5` Define who is the authentification provider , in our case we wants to auth through kerberos for PAM
    - `chpass_provider = krb5` Define who is the Password PAM provider , in our case is kerberos 
    - `krb5_realm = EDT.ORG` Define who is our kerberos5 REALM
    - `krb5_server = 172.18.0.3` Define what is the kerberos5 server (Some problem on Docker with DNS i resolve this putting ip instead FQDN)
    - `krb5_kpasswd = 172.18.0.3` Define what is the kerberos5 password server ( This enable the possibility to `passwd` and change our password
    - `cache_credentials = True` Define if you want keep in cache the credentials (This is needed for work without ethernet connection)
    - `krb5_store_password_if_offline = True` Same the last entry but for password 

- **[nss]**
    - `filter_groups = root` Filter Group root when do nss resoluion
    - `filter_users = root` Filter user root when do nss resolution
    - `reconnection_retries = 3` Try 3 times reconnect and if fail , dont start this process

- **[pam]** 
    - `reconnection_retries = 3` Try connect 3 times when use PAM and if fail dont start this process
    - `offline_credentials_expiration = 2` Days to expire the credentials offline
    - `offline_failed_login_attempts = 3` Chances to fail if offline
    - `offline_failed_login_delay = 5` Delay for fail login offline

Now we have _sssd.conf_ file propery configurated for _Auth:Kerberos User:LDAP Password:Kerberos_ but we need configure _authconfig_ and check PAM before start all.

#### Configure authconfig for enable sssd

## Bibliography

- [LDAP System Administration: Putting Directories to Work](https://books.google.es/books?id=utsMgEfnPSEC&pg=PT56&lpg=PT56&dq=%2B+sasl-secprops+noanonymous,noplain,noactive&source=bl&ots=LonrHJNZVc&sig=kL1iSuR3_4SyJYePIiiJHJ3S4Y8&hl=es&sa=X&ved=0ahUKEwiUoNPW787TAhXInRoKHTCmA7sQ6AEIMDAB#v=onepage&q=%2B%20sasl-secprops%20noanonymous%2Cnoplain%2Cnoactive&f=false)
- [Official OpenLDAP Documentation of SASL Auth](http://www.openldap.org/doc/admin24/sasl.html)
- [Mastering Ldap - Matt Butcher](https://www.packtpub.com/networking-and-servers/mastering-openldap-configuring-securing-and-integrating-directory-services)
