#!/bin/bash

echo "Starting backup process..."

# Read the controller file and create an array of folder names
IFS=$'\r\n' GLOBIGNORE='*' command eval 'folders=($(cat controller_file.txt))'

for folder in "${folders[@]}"
do
	# Database name
	database=$(grep "'DB_NAME'" /home/$folder/public_html/wp-config.php | cut -d "'" -f 4)
	#password=$(grep "'DB_PASSWORD'" /home/$folder/public_html/wp-config.php | cut -d "'" -f 4)
	password="d3m0\$it3\$d8"
	# Create password file with database password
	echo "[mysqldump]" > /home/ubuntu/Backup/password.txt
	echo "password=$password" >> /home/ubuntu/Backup/password.txt
	chmod 600 /home/ubuntu/Backup/password.txt
	echo -e "Database password : \033[33m $password \033[0m"
	# Export database using mysqldump and save backup file
	echo "Starting database export for $database..."
	mysql --defaults-file=/home/ubuntu/sqlpass.txt -e "use $database;" &> /dev/null
	if [ $? -eq 0 ]; then
		mysqldump --defaults-file=/home/ubuntu/Backup/password.txt -u root $database > "/home/ubuntu/Backup/$folder-$(date +"%d-%m-%Y").sql"
	        #mysqldump -u root $database -p > "/home/ubuntu/Backup/$folder-$(date +"%d-%m-%Y").sql"
        	if [ $? -eq 0 ]; then
               	 echo -e "\033[32m Database $database export success \033[0m"
               	 echo "$(date) Database Backup created for site $folder" >> /home/ubuntu/Backup/backup.log
        	else
                 echo -e "\033[31m Database $database export failed with exit code $? \033[0m"
                 echo "$(date) Database Backup FAILED for site $folder" >> /home/ubuntu/Backup/backup.log
                 rm "/home/ubuntu/Backup/$folder-$(date +"%d-%m-%Y").sql"
        	fi
	else
		echo "$(date) Database $database dosent exist" >> /home/ubuntu/Backup/backup.log
	fi
	echo -e "Zipping files for site : \033[35m $folder \033[0m"

	if [ -d /home/$folder ]; then
	 # Zip the folder using the transformed file name
         zip -qr "/home/ubuntu/Backup/$folder"-$(date +"%d-%m-%Y").zip "/home/$folder"
        	if [ $? -eq 0 ]; then
                	echo -e "\033[32m Zipping site $database success \033[0m"
                	echo "$(date) Files Backup created for site $folder" >> /home/ubuntu/Backup/backup.log
        	else
                	echo -e "\033[31m Zipping site $database export failed with exit code $? \033[0m"
                	echo "$(date) Files Backup FAILED for site $folder" >> /home/ubuntu/Backup/backup.log
		fi
	else
                        echo -e "\033[31m Folder $database dosent exist $? \033[0m"
	fi
	# Append log message to backup log file
	echo "Backup created for site $folder at $(date)" >> /home/ubuntu/Backup/backup.log
done

echo "Backup process completed."