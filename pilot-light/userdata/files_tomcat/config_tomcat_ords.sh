#!/bin/bash

# This script requires 6 arguments
# Arg1 : Target db's admin pw
# Arg2 : Target db's IP address, whether public or private is ok as long as it is reachable from compute isntance
# Arg3 : Target db's service name to connect
# Arg4 : Compute IP address for ords
# Arg5 : Compute port for access for ords
# Arg6 : Object Storage URL for ords.war file

# Set Variables
DBAdmPwd=$1
DBSystemIP=$2
DBSrv=$3
DBName=`echo ${DBSrv} | awk -F. '{print $1}'`
ComIP=$4
ComPort=$5
URL_ORDS_file=$6

### Configure ords for the target database
# Download ords.war
curl -v -X GET -o ords.war ${URL_ORDS_file}

source /home/tomcat/.bash_profile

# Update password verify function - MOS 2408087.1
CURRENT_PW_VERIFY_FUNC=`sqlplus -s sys/"${DBAdmPwd}"@${DBSystemIP}/${DBSrv} as sysdba @pw_prof_chk|sed '/^$/d'`
cp pw_verify_base.sql pw_verify_back.sql
sed -i -e "s/ToBeUpdated_PW_VERIFY_FUNC/$CURRENT_PW_VERIFY_FUNC/g" pw_verify_back.sql
sqlplus -s sys/"${DBAdmPwd}"@${DBSystemIP}/${DBSrv} as sysdba @pw_verify_null

# Setup ords for target DB
cp ords_setup_base.exp ords_setup.exp
sed -i -e "s/ToBeUpdated_DBAdmPwd/${DBAdmPwd}/g" ords_setup.exp
sed -i -e "s/ToBeUpdated_DBSystemIP/${DBSystemIP}/g" ords_setup.exp
sed -i -e "s/ToBeUpdated_DBSrv/${DBSrv}/g" ords_setup.exp
sed -i -e "s/ToBeUpdated_DBName/${DBName}/g" ords_setup.exp

java -jar ords.war configdir /home/tomcat/conf

java -jar ords.war map-url --type base-path /${DBName} ${DBName}

expect ords_setup.exp

# Restore password verify function
sqlplus -s sys/"${DBAdmPwd}"@${DBSystemIP}/${DBSrv} as sysdba @pw_verify_back

# Add entries to defaults.xml
cp conf/ords/defaults.xml conf/ords/defaults.xml_orig
sed -i -e '5i <entry key="restEnabledSql.active">true</entry>' conf/ords/defaults.xml
sed -i -e '6i <entry key="misc.pagination.maxRows">10000</entry>' conf/ords/defaults.xml
sed -i -e '7i <entry key="security.verifySSL">false</entry>' conf/ords/defaults.xml

# Copy ords.war to Tomcat webapps directory
cp ords.war /opt/apache-tomcat-*/webapps
ls -l /opt/apache-tomcat-*/webapps

# Update the scripts with the Compute Instance IP and port, give execution permmision to *_add_db.sh
sed -i -e "s/ToBeUpdated_IPAddress/${ComIP}/g" -e "s/ToBeUpdated_Port/${ComPort}/g" *_add_db.sh

# Cleanup 
rm -rf ords_setup.exp pw_verify_back.sql
history -c
