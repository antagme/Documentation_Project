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
CONTAINER_ZABBIX="zabbix"
IMAGE_LDAP="antagme/ldap_zabbix"
IMAGE_KERBEROS="antagme/kerberos:supervisord"
IMAGE_CLIENT="antagme/antagme/client_gssapi"
IMAGE_ZABBIX="antagme/antagme/httpd:zabbix"

#----------------------------------------------------------------------#

# Stop all containers with this names if this is running
echo " STOPING CONTAINERS"
docker stop $CONTAINER_LDAP &> $LOG_FILE
docker stop $CONTAINER_KERBEROS &>> $LOG_FILE
docker stop $CONTAINER_CLIENT &>> $LOG_FILE
docker stop $CONTAINER_ZABBIX &>> $LOG_FILE

# Remove all containers with this names
echo " REMOVING CONTAINERS"
docker rm $CONTAINER_LDAP  &>> $LOG_FILE
docker rm $CONTAINER_KERBEROS  &>> $LOG_FILE
docker rm $CONTAINER_CLIENT  &>> $LOG_FILE
docker rm $CONTAINER_ZABBIX &>> $LOG_FILE

# Remove Images of all Containers?
echo " REMOVING IMAGES"
docker rmi $IMAGE_LDAP  &>> $LOG_FILE
docker rmi $IMAGE_KERBEROS  &>> $LOG_FILE
docker rmi $IMAGE_CLIENT  &>> $LOG_FILE
docker rmi $IMAGE_ZABBIX  &>> $LOG_FILE

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
	&& echo " Ldap Container Created... %25 Completed"

## Docker Kerberos

docker run --name $CONTAINER_KERBEROS \
	--hostname kserver.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.3  --detach  $IMAGE_KERBEROS &>> $LOG_FILE \
	&& echo " Kerberos Container Created ... %50 Completed"
	
## Docker Client
docker run --name $CONTAINER_CLIENT \
	--hostname client.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.8  --detach  $IMAGE_CLIENT &>> $LOG_FILE \
	&& echo " Client Container Created ... %75 Completed"

## Docker Zabbix

docker run --name $CONTAINER_ZABBIX \
	--hostname zabbix.edt.org --net $DOCKER_NETWORK \
	--ip 172.18.0.10  --detach  $IMAGE_ZABBIX &>> $LOG_FILE \
	&& echo " Zabbix Container Created ... %100 Completed"

echo -e " Thanks For the Wait"'!!!'" \n For Access inside Container \
	\n docker exec --interactive --tty [Container Name] bash "
