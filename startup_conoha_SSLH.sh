#!/bin/bash
# -------------------------------------------------------
# Start Up Script for CONOHA VPS CentOS(7.5) SSLH version
# conoha VPS: https://www.conoha.jp/
#
#
# ** This script executed after your instance is created. 
#
#  1. Update packages (yum upgrade.)
#  2. Create a user for ssh access 
#  3. Set up for Public-key-Authentication 
#  4. Disable SSH Root Login 
#  5. Disable SSH Password Login
#  6. Disable All port except https
#  7. Limiting su with wheel group 
#  8. Disable IPv6
#  9. Firewall Setup (by firewalld)
# 10. Firewall Open ${SSH_PORT}
#
## * NO selinux 

#------------------------------------------------
#  Create a user for ssh access 
#------------------------------------------------
USERNAME='darkqueen'

#------------------------------------------------
#  Password is for console login.
# (This password is not available for ssh login.)
#------------------------------------------------
PASSWORD='darkqueen' 

#------------------------------------------------
# Copy and Paste your public-key below.
# This is saved in '.ssh/autholized_keys'.
#------------------------------------------------
PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeFr21JK6W0yDRgmZbqeNFACpQTazK4UMWj/Rv1a3W50yNJuvnbeOxCdrvc8RZJNSZqEZBKXU733cp7XnDmDSyDqCm82nY2/cLfYaJ3w/X+6LoFwCXMbljQ2WK96r1dxBU5rMfXgPy/y2/EEvix4D2PNe9ySLChLeWFd6b+vn5sQzwrifrMLVQcA8HEkIp3HJBoyrzZOkoExOXE7LnslyQkXvS+qNSGweRXOWRmMYnTA4ppXqdPIt7NPZgDlD7zzUwGg84xgw76gi/svsQ4Cw/om20NuOnOPn4SbxZU87IkinEqAybSHOx8QNNiNcTBjARCsRgxt77ClJS+x+wcZS1 darkqueen@darkqueen-Inspiron-11-3162'

#------------------------------------------------
# New SSH port.
# Don't have to change if SSLH is used. 
# ssh -p<SSH_PORT> <ip.of.server.address>
#------------------------------------------------
SSH_PORT=22

#------------------------------------------------
# LOG file name
#------------------------------------------------
LOG='/tmp/startupfile.log'

#################################################
# start 

touch $LOG
echo " startup file: " >$LOG

#
# 1. update CentOS
#    This step takes logtime,
#
echo " Start update. Sometimes this takes long time as 5~10min... ">> $LOG &&\
    yum -q -y makecache &&\
    yum -q -y upgrade  &&\
    echo "upgrade finished" >> $LOG

#
# 2. add new user
#
echo "add user">> $LOG &&\
    useradd -m -G wheel -s /bin/bash "${USERNAME}" &&\
    echo "${PASSWORD}" | passwd --stdin "${USERNAME}"

#
# 3. save public key as an  authorized keys in ~/.ssh/authorized_keys
#
echo "ssh setting for $USERNAME">> $LOG &&\
    mkdir -p  /home/${USERNAME}/.ssh &&\
    chmod 700 /home/${USERNAME}/.ssh &&\
    chown ${USERNAME}  /home/${USERNAME}/.ssh &&\
    echo $PUBLIC_KEY >> /home/${USERNAME}/.ssh/authorized_keys &&\
    chown ${USERNAME} /home/${USERNAME}/.ssh/authorized_keys &&\
    chmod 400 /home/${USERNAME}/.ssh/authorized_keys &&\
    echo "Successfully updated public key! ">>$LOG

#
# 4. change /etc/sudoers for no password 
#
echo "%wheel    ALL=NOPASSWD: ALL" >>/etc/sudoers &&\
    echo "Successfully changed sudoer ">>$LOG

#
# 5. Only  'wheel' group can use 'su' command.
#
sed -e "s/#auth\s*required\s*pam\s*wheel.so /auth required pam_wheel.so /g" -i /etc/pam.d/su &&\
    echo "Successfully changed su availablity">>$LOG

#
# 6. sshd config
#
echo "sshd setting start">>$LOG
# no root login
sed -e "s/#*\s*PermitRootLogin\s*yes/PermitRootLogin no/g" -i /etc/ssh/sshd_config 
sed -e "s/#*\s*PermitRootLogin\s*no/PermitRootLogin no/g" -i /etc/ssh/sshd_config

# ENABLE Pubkey Authentication 
sed -e "s/#*\s*PubkeyAuthentication\s*yes/PubkeyAuthentication yes/g" -i /etc/ssh/sshd_config
sed -e "s/#*\s*PubkeyAuthentication\s*no/PubkeyAuthentication yes/g" -i /etc/ssh/sshd_config

# DISABLE Password Login
sed -e "s/#*\s*PasswordAuthentication\s*yes/PasswordAuthentication no/g" -i /etc/ssh/sshd_config
sed -e "s/#*\s*PasswordAuthentication\s*no/PasswordAuthentication no/g" -i /etc/ssh/sshd_config

# change Port Number for ssh
# ssh -p 443 
sed -e "s/#Port\s*22 */Port ${SSH_PORT}/g" -i /etc/ssh/sshd_config && echo "End edit sshd_config ">>$LOG

# restrt sshd
systemctl restart sshd && echo "sshd restarted. ">>$LOG

# ip address 
IP_ADDRESS=`ip -br address |grep -v ^lo|sed -e 's/.*UP *//'g|sed -e's#/.*##'` &&\
    echo $IP_ADDRESS >>$LOG

#
# edit /etc/sslh.cfg
#
echo "sslh install start" >>$LOG
yum -q -y install epel-release &&\
    yum  -q -y install sslh &&\
    echo "sslh is installed. setup the config file" &&\
    sed -e 's/thelonious/'${IP_ADDRESS}'/' -i /etc/sslh.cfg &&\
    sed -e 's/ port:\s*"22"\s*;/ port: "'${SSH_PORT}'"/' -e '/name: "xmpp"/'d -i /etc/sslh.cfg &&\
    systemctl enable sslh &&\
    systemctl start sslh  &&\
    echo "sslh setup end." >>$LOG


# ----------------------------------------------------
# firewall setting 
# ---------------------------------------------------
sed -e 's/port="22"/port="'${SSH_PORT}'"/g' -i /usr/lib/firewalld/services/ssh.xml
firewall-cmd --zone=public --remove-service=ssh --permanent &&\
    firewall-cmd --zone=public --remove-service=dhcpv6-client --permanent &&\
    firewall-cmd --zone=public --add-service=https --permanent &&\
    firewall-cmd --reload
#    firewall-cmd --zone=public --add-port=${SSH_PORT}/tcp --permanent &&\


# ----------------------------------------------------
# disable ipv6
# ----------------------------------------------------
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 &&\
    echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6

# ----------------------------------------------------
# ADD SET any setup Below
# ----------------------------------------------------


echo "END: startup_script  ">>$LOG
