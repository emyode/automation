#!/bin/bash

# Vérifiez les arguments
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <new_hostname> <accountName> <accountKey> <containerName> [environment]"
    exit 1
fi

new_hostname=$1
accountName=$2
accountKey=$3
containerName=$4
environment=$5

# Changer le nom du serveur
echo "Changing hostname..."
sudo sed -i "s/old_hostname/$new_hostname/g" /etc/hosts
echo "$new_hostname" | sudo tee /etc/hostname

# Modifier le fichier fuseAzureStorage.cfg
echo "accountName $accountName" | sudo tee -a /etc/fuseAzureStorage.cfg
echo "accountKey $accountKey" | sudo tee -a /etc/fuseAzureStorage.cfg
echo "containerName $containerName" | sudo tee -a /etc/fuseAzureStorage.cfg

# Configurer blobfuse
echo "Configuring blobfuse..."
sudo blobfuse /bitnami/AzureStorage/ --tmp-path=/mnt/resource/blobfusetmp --config-file=/etc/fuseAzureStorage.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other

# Créer le répertoire et le fichier test dans AzureStorage
cd /bitnami/AzureStorage/
sudo mkdir -p dbmysqlmoodlebck
sudo touch test.txt

# Optimisation de la mémoire
cd /opt/bitnami/mariadb/conf
echo "Optimising memory..."
if [ "$environment" == "QA" ] || [ "$environment" == "UAT" ]; then
    sudo sed -i 's/innodb_buffer_pool_size=.*/innodb_buffer_pool_size=6012954214/g' my.cnf
elif [ "$environment" == "PROD" ]; then
    sudo sed -i 's/innodb_buffer_pool_size=.*/innodb_buffer_pool_size=12884901888/g' my.cnf
else
    echo "Specify environment (QA, UAT or PROD) as the 5th argument"
    exit 1
fi

echo "Script completed."
