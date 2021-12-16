#!/bin/bash

#open directory
nextcloud_docker_path=`realpath $(dirname $(readlink -f $0))/../`
cd $nextcloud_docker_path


source .env

LOCAL_IMAGE="nextcloud"
DOCKERHUB_LIST_TAGS=($(wget -q https://registry.hub.docker.com/v1/repositories/$LOCAL_IMAGE/tags -O - | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep '^[0-9]' | grep -v '-' | grep -v '\.[0-9]\.'))


echo "Available Nextcloud versions: ${DOCKERHUB_LIST_TAGS[*]: -20 : 18}"  

echo "Your desired tag: $WEB_DOCKER_IMAGE"
 
nc_version=$(docker inspect $WEB_DOCKER_IMAGE|grep NEXTCLOUD_VERSION -m1 | cut -d = -f 2 |cut -d \" -f 1)


echo "Your current Nextcloud-Version: $nc_version"
echo
echo "Do you want to procced?"

select opt in yes no
do
    case $opt in
        "yes")
            echo "update..."
			break
            ;;
        "no")
            echo "exit..."
			exit 1
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


# uncomment to interupt
# exit 0

#enable maintenace mode
#bash $nextcloud_docker_path/scripts/nextcloud_scripts/maintenance_enable.sh 

# make snapper create here
N=$(snapper -c docker create -d "NC update to $nc_version pre" -t pre -p)

# Stop nextcloud docker instance
sudo systemctl stop nextcloud.service


#pull docker image update
docker-compose pull

nc_version=$(docker inspect $WEB_DOCKER_IMAGE|grep NEXTCLOUD_VERSION -m1 | cut -d = -f 2 |cut -d \" -f 1)
echo "Your updated Nextcloud-Version is: $nc_version"
echo
echo "Do you want to procced with a start of nextcloud?"

select opt in yes no
do
    case $opt in
        "yes")
            echo "start nextcloud..."
			break
            ;;
        "no")
            echo "exit..."
			exit 1
            ;;
        *) echo "invalid option $REPLY";;
    esac
done



# Start nextcloud docker instance
sudo systemctl start nextcloud.service


docker exec -it -u www-data nc_cron php /var/www/html/occ upgrade


snapper -c docker create -d "NC update post" -t post --pre-number $N

#disable maintenace mode
#bash $nextcloud_docker_path/scripts/nextcloud_scripts/maintenance_disable.sh
