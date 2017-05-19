# Example FAST 3 - Client with PAM + SSSD for Kerberos Auth , LDAP user information and Kerberos Password

## Overview

In this model, starting from example one, we will see how to make a more secure authentication in the system using the best of Kerberos and Ldap technologies.

Using this a _Client_ for simulate a school computer.

For this example, in the Client we will see how the System-Auth works with these two technologies, and we will perform a series of checks to make sure it works correctly.

## Requisites

- Docker Engine working on the system
- Run this with user with permisions

Note:_This Script only tested in Fedora 24_

## How To Deploy

If you want to see how it works in your computer , follow this steps.

- Download the start script [start_example3.sh](../../raw/master/AutomatedScript/start_example3.sh)
- Run it `/bin/bash start_example3.sh`
- Wait to finish the installation

## Try it

We gonna log with user in the Client , for this you need enter into the _Client Container_.

    docker exec --interactive --tty client bash
    
Time to try how works.
First we gonna log with **user05** , he have LDAP Entry but not Kerberos , so he doesnt able to _System Auth_ the Ldap Password is _jupiter_

    su user05
    
Now we gonna try log with **user01** with _kuser01_ password. This one have Kerberos entry and LDAP one too. He will enter inside the user.

	su user01

Now try again to perform some checks:

- Check if we got the properly user ticket
	- `klist`
- Check if LDAP server recognize this
	- `ldapwhoami -ZZ`
- Now , do a search
	- `ldapsearch -ZZ cn=user01`
    

Now we have a way to System Authentification more secure than only LDAP.
    
If you preffer long explanation , you have [How to configure for perform Kerberos System Auth](https://github.com/antagme/Documentation_Project/blob/master/example3.md)

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
IMAGE_LDAP="antagme/ldap_sssd"
IMAGE_KERBEROS="antagme/kerberos:supervisord"
IMAGE_CLIENT="antagme/client:pam_tls"

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
echo " REMOVING IMAGES"
docker rmi $IMAGE_LDAP  &>> $LOG_FILE
docker rmi $IMAGE_KERBEROS  &>> $LOG_FILE
docker rmi $IMAGE_CLIENT  &>> $LOG_FILE

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
