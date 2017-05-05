# Example 2 - StartTLS LDAP Producer Server Replicating without SASL GSSAPI Auth and with it

## Overview
In this model, we will see how an _LDAP Server_ works as _Producer_ so that other _LDAP servers_ can replicate and act as Consumer.

We will have the _Consumer_ communicate with the _Producer_ through _simple authentication_.

On the other hand we will make another _Consumer_ do the same but through _SASL GSSAPI authentication_.

Finally we will verify that the **Client** can perform searches in both servers, and we will make modifications in the database of the _Producer_ and we will verify if it is really producing a correct replication.

_Docker Images_ used for this example:
- [Ldap StartTLS Producer + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_producer/)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client for try some consults to Database](https://hub.docker.com/r/antagme/client_gssapi/)
- [Ldap StartTLS Consumer with Simple Authentication](https://hub.docker.com/r/antagme/ldap_replica_simple/)
- [Ldap StartTLS Consumer with SASL GSSAPI Authentication](https://hub.docker.com/r/antagme/ldap_replica_gssapi/)


### Fast Deployment

I Made this example for show how to configure yours _Ldap Servers_ , anyway if you only want check how to it works , maybe be interesed in this another explanation.[Automated Build and How it Works](https://github.com/antagme/Documentation_Project/blob/master/example2fast.md)

## Features

- Openldap Server for use to backup user information
- Secure GSSAPI Authentification for LDAP client utilities
- Secure connection between client and server using StartTLS
- Fastest operations with LDAP Client Utilities
- Ldap Producer Server 
- Ldap Consumer Server with simple authentification
- Ldap Consumer Server with GSSAPI authentification

## Requisites

- [Nslcd and nsswitch file configurated for host retrieving](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md)
- Own Certificates for CA and Server with properly FQDN in Server Certificate.


## Instalation
### Hostnames and our ips

- LDAP Producer Server: ldap.edt.org 172.18.0.2
- Kerberos Server: kserver.edt.org 172.18.0.3
- Client: client.edt.org  172.18.0.8
- LDAP GSSAPI Replica ldaprepl.edt.org 172.18.0.4
- LDAP SIMPLE Replica ldaprepl2.edt.org 172.18.0.5

### Starting
Starting from the base that we already have an openldap server running without these technologies.
To properly configure the servers and the client, we have to be careful in 3 essential things.

- Need to have working the GSSAPI Auth On Ldap Producer and GSSAPI Replica , if you dont have it please see [Example 1](https://github.com/antagme/Documentation_Project/blob/master/example1.md)
- Communication between the Ldap Producer and GSSAPI Replica is correct
- Change the ACL on Ldap Producer For Simple Replica and check if the Communication between Producer and Simple Replica is correct


In our case for this example we will use some docker containers that I created for the occasion.
In these containers are already made the modifications, are just an example, you can do it on your own server
If you dont want use my examples , go directly to [Configure](#configure).

Note: My Containers can communicate between them , because i configurated ldap for do ip resolution [Here](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md) , if u don't using my containers , you should put all container entries in **/etc/hosts** for each container , like this.

    172.18.0.2 ldap.edt.org
    172.18.0.3 kserver.edt.org
    172.18.0.8 client.edt.org
    ldaprepl.edt.org 172.18.0.4
    ldaprepl2.edt.org 172.18.0.5
    
#### Create Docker Network

_This is for a very important reason, we need to always have the same container IP for the proper Ip distribution through LDAP and NSLCD.
In the default Bridge Network , we can't assign ips for containers_


 ```bash
 # docker network create --subnet 172.18.0.0/16 -d bridge ldap
 ```
 
#### Run Docker LDAP
 ```bash
 # docker run --name ldap --hostname ldap.edt.org --net ldap --ip 172.18.0.2  --detach antagme/ldap_producer
 ```  

#### Run Docker Kerberos (TGT)  
 ```bash
 # docker run --name kerberos --hostname kserver.edt.org --net ldap --ip 172.18.0.3  --detach antagme/kerberos:supervisord
 ```
 
#### Run Docker Client   
 ```bash
 # docker run --name client --hostname client.edt.org --net ldap --ip 172.18.0.8 --detach antagme/client_gssapi
 ```

#### Run Docker Replica Simple   
 ```bash
 # docker run --name ldap_replica_gssapi --hostname ldaprepl.edt.org --net ldap --ip 172.18.0.4 --detach antagme/ldap_replica_gssapi
 ```
 
 #### Run Docker Replica Simple   
 ```bash
 # docker run --name ldap_replica_simple --hostname ldaprepl2.edt.org --net ldap --ip 172.18.0.5 --antagme/ldap_replica_client
 ```

These dockers containers are not interactive, to access you have to do the following order:

    docker exec --interactive --tty [Docker Name] bash
    
#### Automated Script
If you preffer to use an Automated Builds , can take the script i created for this.[HERE](https://github.com/antagme/Documentation_Project/blob/master/AutomatedScript/start_example2.sh)
