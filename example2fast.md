# Example 2 FAST - StartTLS LDAP Producer Server Replicating without SASL GSSAPI Auth and with it

## Overview
In this model, we will see how an _LDAP Server_ works as _Producer_ so that other _LDAP servers_ can replicate and act as Consumer.

We will have the _Consumer_ communicate with the _Producer_ through _simple authentication_.

On the other hand we will make another _Consumer_ do the same but through _SASL GSSAPI authentication_.

Finally we will verify that the **Client** can perform searches in both servers, and we will make modifications in the database of the _Producer_ and we will verify if it is really producing a correct replication.

## Requisites

- Docker Engine working on the system
- Run this with user with permisions

Note:_This Script only tested in Fedora 24_

## How To Deploy

If you want to see how it works in your computer , follow this steps.

- Download the start script `wget https://raw.githubusercontent.com/antagme/Documentation_Project/master/AutomatedScript/start_example2.sh`
- Run it `/bin/bash start_example2.sh`
- Wait to finish the installation

## Try it

We gonna try some search querys with Client , you need enter into the _Client Container_.

    docker exec --interactive --tty client bash
    
Time to try how works.
First we perform searchs on the Replica Servers.

    ldapsearch -h ldaprepl.edt.org -x -ZZ
    ldapsearch -h ldaprepl2.edt.org -x -ZZ

Is the same information , now we gonna put some new information in _Producer_ and check if the information was updated in the Replicas

    docker exec --interactive --tty ldap bash -c "echo admin | kinit admin/admin && ldapadd -ZZ -f /opt/docker/add_entry.ldif"


Now try again to perform searchs in replica

    ldapsearch -h ldaprepl.edt.org -x -ZZ
    ldapsearch -h ldaprepl2.edt.org -x -ZZ

Now we have the information updated in the Replica Servers! You can use this for balance traffic or only for do _Backups_.
    
If you preffer long explanation , you have [How to configure for perform Replication](https://github.com/antagme/Documentation_Project/blob/master/example2.md)

```INI
#!/bin/bash
# Author: Pedro Romero Aguado
# Date: 04/05/2017
# Script for Start Network and the Docker Containers Needed for Example
# If you want check the logs , its posible in $LOG_FILE variable

#SET LOG FILE
LOG_FILE="/dev/stdout"
#SET NETWORK NAME
DOCKER_NETWORK="ldap"
#SET CONTAINERS AND IMAGES NAMES
CONTAINER_LDAP="ldap"
CONTAINER_KERBEROS="kerberos"
CONTAINER_CLIENT="client"
CONTAINER_REPLICA_SIMPLE="ldap_replica_simple"
CONTAINER_REPLICA_GSSAPI="ldap_replica_gssapi"
#
IMAGE_LDAP="antagme/ldap_producer"
IMAGE_KERBEROS="antagme/kerberos:supervisord"
IMAGE_CLIENT="antagme/client_gssapi"
IMAGE_REPLICA_SIMPLE="antagme/ldap_replica_simple"
IMAGE_REPLICA_GSSAPI="antagme/ldap_replica_gssapi"
#----------------------------------------------------------------------#

# Stop all containers with this names if this is running
echo " STOPING CONTAINERS"
docker stop $CONTAINER_LDAP &> $LOG_FILE
docker stop $CONTAINER_KERBEROS &>> $LOG_FILE
docker stop $CONTAINER_CLIENT &>> $LOG_FILE
docker stop $CONTAINER_REPLICA_SIMPLE &>> $LOG_FILE
docker stop $CONTAINER_REPLICA_GSSAPI &>> $LOG_FILE

# Remove all containers with this names
echo " REMOVING CONTAINERS"
docker rm $CONTAINER_LDAP  &>> $LOG_FILE
docker rm $CONTAINER_KERBEROS  &>> $LOG_FILE
docker rm $CONTAINER_CLIENT  &>> $LOG_FILE
docker rm $CONTAINER_REPLICA_SIMPLE &>> $LOG_FILE
docker rm $CONTAINER_REPLICA_GSSAPI &>> $LOG_FILE

# Remove Images of all Containers?
echo " REMOVING IMAGES"
docker rmi $IMAGE_LDAP  &>> $LOG_FILE
docker rmi $IMAGE_KERBEROS  &>> $LOG_FILE
docker rmi $IMAGE_CLIENT  &>> $LOG_FILE
docker rmi $IMAGE_REPLICA_SIMPLE  &>> $LOG_FILE
docker rmi $IMAGE_REPLICA_GSSAPI  &>> $LOG_FILE

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
	&& echo " Ldap Container Created... %20 Completed"

## Docker Kerberos

docker run --name $CONTAINER_KERBEROS \
	--hostname kserver.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.3  --detach  $IMAGE_KERBEROS &>> $LOG_FILE \
	&& echo " Kerberos Container Created ... %40 Completed"
	
## Docker Client
docker run --name $CONTAINER_CLIENT \
	--hostname client.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.8  --detach  $IMAGE_CLIENT &>> $LOG_FILE \
	&& echo " Client Container Created ... %60 Completed"

## Docker Replica GSSAPI

docker run --name $CONTAINER_REPLICA_GSSAPI \
	--hostname ldaprepl.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.4  --detach  $IMAGE_REPLICA_GSSAPI &>> $LOG_FILE \
	&& echo " Ldap Replica GSSAPI Container Created ... %80 Completed"

## Docker Replica Simple

docker run --name $CONTAINER_REPLICA_SIMPLE \
	--hostname ldaprepl2.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.5  --detach  $IMAGE_REPLICA_SIMPLE &>> $LOG_FILE \
	&& echo " Ldap Replica Simple Container Created ... %100 Completed"

## Starting Slapd Replica GSSAPI
docker exec --interactive --tty ldap_replica_gssapi bash -c "echo admin | kinit admin/admin && supervisorctl start slapd"

## Starting Slapd Replica Simple
docker exec --interactive --tty ldap_replica_simple bash -c "supervisorctl start slapd"

echo -e " Thanks For the Wait"'!!!'" \n For Access inside Container \
	\n docker exec --interactive --tty [Container Name] bash "

```
