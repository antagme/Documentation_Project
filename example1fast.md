# Example 1 FAST - StartTLS LDAP Server With SASL GSSAPI Auth

## Overview

In this model, we will perform a _GSSAPI Authentication_ using the Openldap client utilities. For this we will use a total of 3 _Docker Containers_.
All communication between the client and the _LDAP SERVER_ is encrypted using the _TLS_ protocol, using port 389, the default for unencrypted communications, but thanks to _StartTLS_, we can use it for secure communications

## Requisites

- Docker Engine working on the system
- Run this with user with permisions

Note:_This Script only tested in Fedora 24_

## How To Deploy

If you want to see how it works in your computer , follow this steps.

- Download the start script [start_example1.sh](../../raw/master/AutomatedScript/start_example1.sh)
- Run it `/bin/bash start_example1.sh`
- Wait to finish the installation

## Try it

We gonna try some search querys with Client , you need enter into the _Client Container_.

    docker exec --interactive --tty client bash
    
Time to try how works.
First need get a _Kerberos User Ticket_.

    kinit user01
    
The password is `kuser01`

Check if the ticket is getting properly.

    klist

Check if ldap transform properly the ticket.

    ldapwhoami -ZZ
    
Now try some Ldapsearch querys.

    ldapsearch -ZZ cn=user01
    
## More information

If you preffer long explanation , you have [How to configure for perform SASL GSSAPI](https://github.com/antagme/Documentation_Project/blob/master/example1.md)

```INI
## Script Code
#!/bin/bash
# Author: Pedro Romero Aguado
# Date: 04/05/2017
# Script for Start Network and the Docker Containers Needed for Example
# If you want check the logs , its posible in $LOG_FILE variable

#SET LOG FILE
LOG_FILE="/var/tmp/log_script"
#SET NETWORK NAME
DOCKER_NETWORK="ldap"
#SET CONTAINERS AND IMAGES NAMES
CONTAINER_LDAP="ldap"
CONTAINER_KERBEROS="kerberos"
CONTAINER_CLIENT="client"
IMAGE_LDAP="antagme/ldap_gssapi"
IMAGE_KERBEROS="antagme/kerberos:supervisord"
IMAGE_CLIENT="antagme/client_gssapi"

#----------------------------------------------------------------------#

# Stop all containers with this names if this is running
echo " STOPING CONTAINERS"
docker stop $CONTAINER_LDAP &> $LOG_FILE
docker stop $CONTAINER_KERBEROS &>> $LOG_FILE
docker stop $CONTAINER_CLIENT &>> $LOG_FILE

# Remove all containers with this names
echo " REMOVING CONTAINERS"
docker rm $CONTAINER_LDAP  &>> $LOG_FILE
docker rm $CONTAINER_KERBEROS  &>> $LOG_FILE
docker rm $CONTAINER_CLIENT  &>> $LOG_FILE

# Remove Images of all Containers?
#echo " REMOVING IMAGES"
#docker rmi $IMAGE_LDAP  &>> $LOG_FILE
#docker rmi $IMAGE_KERBEROS  &>> $LOG_FILE
#docker rmi $IMAGE_CLIENT  &>> $LOG_FILE

#REMOVE IF EXISTS 
echo " Deleting Network"
docker network rm $DOCKER_NETWORK &>> $LOG_FILE

#CREATE NETWORK
echo " Creating Network"
docker network create --subnet 172.18.0.0/16 --driver bridge \
	$DOCKER_NETWORK &>> $LOG_FILE \
	&& echo " Docker Network $DOCKER_NETWORK Created"

# Run Containers
## Docker LDAP
echo " RUNNING CONTAINERS IT CAN TAKE A WHILE...WAIT PLEASE!!!"

docker run --name $CONTAINER_LDAP \
	--hostname ldap.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.2  --detach $IMAGE_LDAP &>> $LOG_FILE \
	&& echo " Ldap Container Created... %33 Completed"

## Docker Kerberos

docker run --name $CONTAINER_KERBEROS \
	--hostname kserver.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.3  --detach  $IMAGE_KERBEROS &>> $LOG_FILE \
	&& echo " Kerberos Container Created ... %66 Completed"
	
## Docker Client
docker run --name $CONTAINER_CLIENT \
	--hostname client.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.8  --detach  $IMAGE_CLIENT &>> $LOG_FILE \
	&& echo " Client Container Created ... %100 Completed"
	
echo -e " Thanks For the Wait"'!!!'" \n For Access inside Container \
	\n docker exec --interactive --tty [Container Name] bash "
```
