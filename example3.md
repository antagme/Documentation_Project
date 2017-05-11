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
#### 

## Bibliography

- [LDAP System Administration: Putting Directories to Work](https://books.google.es/books?id=utsMgEfnPSEC&pg=PT56&lpg=PT56&dq=%2B+sasl-secprops+noanonymous,noplain,noactive&source=bl&ots=LonrHJNZVc&sig=kL1iSuR3_4SyJYePIiiJHJ3S4Y8&hl=es&sa=X&ved=0ahUKEwiUoNPW787TAhXInRoKHTCmA7sQ6AEIMDAB#v=onepage&q=%2B%20sasl-secprops%20noanonymous%2Cnoplain%2Cnoactive&f=false)
- [Official OpenLDAP Documentation of SASL Auth](http://www.openldap.org/doc/admin24/sasl.html)
- [Mastering Ldap - Matt Butcher](https://www.packtpub.com/networking-and-servers/mastering-openldap-configuring-securing-and-integrating-directory-services)
