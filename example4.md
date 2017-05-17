# Example 4 - Zabbix Monitoring to Monitor Database from Openldap Server

## Overview

Finally, in this model, we will see in a Zabbix server how to have monitored by graphs, all the operations that are done in our LDAP Server and all connections to it.

_Docker Images_ used for this example:
- Ldap StartTLS with Crond Python Script
- Kerberos
- Client for do some searchs and see the graphs
- Zabbix with Openldap Custom Template

### Fast Deployment

I Made this example for show how to configure your _Ldap Server_ , anyway if you only want check how to it works , maybe be interesed in this another explanation.[Automated Build and How it Works](https://github.com/antagme/Documentation_Project/blob/master/example4fast.md)

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

```INI
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

I do not know exactly what is the best configuration about authconfig , this tool is a headcache at all , so i will put you my configuration file and if you want to do for you , you are welcome to try it and help me to improve.

The [file](https://raw.githubusercontent.com/antagme/client/master/files/authconfig) is:

    IPADOMAINJOINED=no
    PASSWDALGORITHM=sha512
    USESSSD=yes
    USEMKHOMEDIR=no
    USEDB=no
    USEPASSWDQC=no
    USESSSDAUTH=yes
    USEHESIOD=no
    CACHECREDENTIALS=yes
    USESYSNETAUTH=no
    USEECRYPTFS=no
    USESMARTCARD=no
    USEWINBINDAUTH=no
    USEIPAV2=no
    USELDAP=yes
    WINBINDKRB5=no
    USELOCAUTHORIZE=yes
    USEKERBEROS=yes
    USELDAPAUTH=no
    USEPAMACCESS=no
    USEWINBIND=no
    FORCELEGACY=no
    USEPWQUALITY=yes
    USENIS=no
    FORCESMARTCARD=no
    USESHADOW=yes
    USEFPRINTD=no
    IPAV2NONTP=no

 You should copy this to `/etc/sysconfig/` and perform this order  `authconfig --update`
 
 Now my recommendation is check your `/etc/krb5.conf`, `/etc/nsswitch/` and `/etc/openldap/ldap.conf` for make sure this files not changed for authconfig.
 
 #### Pam Configuration
 
 Now for reach our objetive only need if our pam configuration is the needed and if not , configure this.
 
 We need to configure `su` and `system-auth`PAM files for properly `system authentification` .
 
 Lets see my files(the location is `/etc/pam.d/`):
 
 [`su`](https://raw.githubusercontent.com/antagme/client/master/files/pam.d/su) PAM file:
```INI
 #%PAM-1.0
auth		substack	system-auth
auth		include		postlogin
account		sufficient	pam_succeed_if.so uid = 0 use_uid quiet
account		include		system-auth
password	include		system-auth
session		include		system-auth
session		include		postlogin
session optional pam_xauth.so
```

Note: _This check all from system-auth PAM file_

[`system-auth`](https://raw.githubusercontent.com/antagme/client/master/files/pam.d/system-auth) PAM FILE:
```INI
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth        [default=1 success=ok] pam_localuser.so
auth        [success=done ignore=ignore default=die] pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
auth        sufficient    pam_sss.so use_authtok
auth        sufficient    pam_krb5.so use_first_pass
auth        required      pam_deny.so

account     required      pam_unix.so broken_shadow
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     [default=bad success=ok user_unknown=ignore] pam_krb5.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient    pam_sss.so user_authtok
password    sufficient    pam_krb5.so use_authtok
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
session     optional      pam_sss.so
session optional pam_krb5.so
```

The system authentification process will check if this account is UNIX , if not , check if kerberos account.

Note:_I know this PAM file is not the perfect configuration , fell free to help me to improve_

#### Client Authentification

Now is time to check if our configuration is working well!!! We need to start `sssd` daemon in the client machine.
In our case , we will `supervisorctl start sssd` and we gonna try if the client can start properly with a kerberos user.

We gonna try with our **user01** he have _kuser01_ password.

    su user01

now check with `id` and `who` the identity of the user.

and finally check who we are in Ldap Database.

    ldapwhoami -ZZ
    
We configured the system authentification for perform _Kerberos_ **authentification** , **account** information from _Ldap_ and finally the **password** will be retrieved from _Kerberos_

## Bibliography

- [authconfig Documentation from Red Hat](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System-Level_Authentication_Guide/authconfig-install.html)
- [Fedora Documentation for SSSD Configuration](https://docs.fedoraproject.org/en-US/Fedora/14/html/Deployment_Guide/chap-SSSD_User_Guide-Introduction.html)
- [Mastering Ldap - Matt Butcher](https://www.packtpub.com/networking-and-servers/mastering-openldap-configuring-securing-and-integrating-directory-services)
