#!/bin/bash
# -------------------------------------------------------
# Start Up Script for CONOHA VPS CentOS(7.5) SSLH version
# conoha VPS: https://www.conoha.jp/
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
#  8. Disable IPv6 (NetworkManager)
#  9. Firewall Setup (for firewalld)
# 10. Firewall Open ${SSH_PORT}
# 11. install docker
## * NO selinux 

#------------------------------------------------
#  Create a user for ssh access 
#------------------------------------------------
USERNAME='darkqueen'

#-----------------------------------------------
# This is saved in '.ssh/autholized_keys'.
# (Let me leave my public key in public here.)
# Copy can be done easily by 'xsel -ib'
# $cat ~/.ssh/id_rsa.pub |xsel -ib
#-----------------------------------------------
PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeFr21JK6W0yDRgmZbqeNFACpQTazK4UMWj/Rv1a3W50yNJuvnbeOxCdrvc8RZJNSZqEZBKXU733cp7XnDmDSyDqCm82nY2/cLfYaJ3w/X+6LoFwCXMbljQ2WK96r1dxBU5rMfXgPy/y2/EEvix4D2PNe9ySLChLeWFd6b+vn5sQzwrifrMLVQcA8HEkIp3HJBoyrzZOkoExOXE7LnslyQkXvS+qNSGweRXOWRmMYnTA4ppXqdPIt7NPZgDlD7zzUwGg84xgw76gi/svsQ4Cw/om20NuOnOPn4SbxZU87IkinEqAybSHOx8QNNiNcTBjARCsRgxt77ClJS+x+wcZS1 darkqueen@darkqueen-Inspiron-11-3162'

#------------------------------------------------
#  Password is for console login. (OPTION)
#  This password is not available for ssh login, 
#  only used for console login.
#  If This is None, a random password is used
#  which mean console-login is disabled.
#------------------------------------------------
PASSWORD='' 
[ x${PASSWORD} == 'x' ] && PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 14 | head -n 1)

#------------------------------------------------
# New SSH port. 
# You DONOT have to change this setting, becasue
# this port is not open for extarnal users. 
#
# ssh -p443 <ip.of.server.address>
#------------------------------------------------
SSH_PORT=22

#------------------------------------------------
# LOG file name
#------------------------------------------------
LOG='/var/log/startupfile.log'

#################################################
# start 
#################################################
function logging_INFO() {
  local _fname=${BASH_SOURCE[1]##*/ }
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') [INFO ] ${_fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}: $@" | tee -a ${LOG}
}
function logging_DEBUG() {
  local _fname=${BASH_SOURCE[1]##*/ }
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') [DEBUG] ${_fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}: $@" | tee -a ${LOG}
}
function logging_WARN() {
  local _fname=${BASH_SOURCE[1]##*/ }
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') [WARN ] ${_fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}: $@" | tee -a ${LOG}
}
function logging_ERROR() {
  local _fname=${BASH_SOURCE[1]##*/ }
  echo -e "$(date '+%Y-%m-%dT%H:%M:%S') [ERROR] ${_fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}: $@" | tee -a ${LOG}
}

touch $LOG
logging_INFO " startup file" 

#
# 1. update CentOS
#    This step takes logtime,
#
echo " Start update. Sometimes this takes long time as 5~10min... ">> $LOG &&\
    yum -q -y makecache &&\
    yum -q -y upgrade  &&\
    logging_INFO "upgrade finished"

#
# 2. add new user
#
logging_INFO "add user" &&\
    useradd -m -G wheel -s /bin/bash "${USERNAME}" &&\
    echo "${PASSWORD}" | passwd --stdin "${USERNAME}"

#
# 3. save public key as an  authorized keys in ~/.ssh/authorized_keys
#
logging_INFO "ssh setting for $USERNAME" &&\
    mkdir -p  /home/${USERNAME}/.ssh &&\
    chmod 700 /home/${USERNAME}/.ssh &&\
    chown ${USERNAME}  /home/${USERNAME}/.ssh &&\
    echo $PUBLIC_KEY >> /home/${USERNAME}/.ssh/authorized_keys &&\
    chown ${USERNAME} /home/${USERNAME}/.ssh/authorized_keys &&\
    chmod 400 /home/${USERNAME}/.ssh/authorized_keys &&\
    logging_INFO "Successfully updated public key! "

#
# 4. change /etc/sudoers for no password 
#
echo "%wheel    ALL=NOPASSWD: ALL" >>/etc/sudoers &&\
    logging_INFO "Successfully changed sudoer "

#
# 5. Only  'wheel' group can use 'su' command.
#
sed -e "s/#auth\s*required\s*pam\s*wheel.so /auth required pam_wheel.so /g" -i /etc/pam.d/su &&\
    logging_INFO "Successfully changed su availablity"

#
# 6. sshd config
#
logging_INFO "sshd setting start"
# no root login
sed -e "s/#*\s*PermitRootLogin\s*yes/PermitRootLogin no/g" -i /etc/ssh/sshd_config 
sed -e "s/#*\s*PermitRootLogin\s*no/PermitRootLogin no/g" -i /etc/ssh/sshd_config

# 7. ENABLE Pubkey Authentication 
sed -e "s/#*\s*PubkeyAuthentication\s*yes/PubkeyAuthentication yes/g" -i /etc/ssh/sshd_config
sed -e "s/#*\s*PubkeyAuthentication\s*no/PubkeyAuthentication yes/g" -i /etc/ssh/sshd_config

# 8. DISABLE Password Login
sed -e "s/#*\s*PasswordAuthentication\s*yes/PasswordAuthentication no/g" -i /etc/ssh/sshd_config
sed -e "s/#*\s*PasswordAuthentication\s*no/PasswordAuthentication no/g" -i /etc/ssh/sshd_config

# 9. change Port Number for ssh
# ssh -p 443 
sed -e "s/#Port\s*22 */Port ${SSH_PORT}/g" -i /etc/ssh/sshd_config && echo "End edit sshd_config ">>$LOG

# restrt sshd
systemctl restart sshd &&\
logging_INFO "sshd restarted. "

# ip address 
IP_ADDRESS=`ip -br address |grep -v ^lo|sed -e 's/.*UP *//'g|sed -e's#/.*##'` &&\
    export $IP_ADDRESS &&\
    logging_INFO "IP ADDRESS: $IP_ADDRESS" 

#
# edit /etc/sslh.cfg
#
logging_INFO "sslh install start" 
yum -q -y install epel-release &&\
    yum  -q -y install sslh &&\
    logging_INFO "sslh is installed. setup the config file" &&\
    sed -e 's/thelonious/'${IP_ADDRESS}'/' -i /etc/sslh.cfg &&\
    sed -e 's/ port:\s*"22"\s*;/ port: "'${SSH_PORT}'"/' -e '/name: "xmpp"/'d -i /etc/sslh.cfg &&\
    systemctl enable sslh &&\
    systemctl start sslh  &&\
    logging_INFO "sslh setup end." 


# ----------------------------------------------------
# firewall setting 
# ---------------------------------------------------
sed -e 's/port="22"/port="'${SSH_PORT}'"/g' -i /usr/lib/firewalld/services/ssh.xml
firewall-cmd --zone=public --remove-service=ssh --permanent &&\
    firewall-cmd --zone=public --remove-service=dhcpv6-client --permanent &&\
    firewall-cmd --zone=public --add-service=https --permanent &&\
    firewall-cmd --reload &&\
    logging_INFO "firewall setting end."
#    firewall-cmd --zone=public --add-port=${SSH_PORT}/tcp --permanent &&\


# ----------------------------------------------------
# disable ipv6
# ----------------------------------------------------
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 &&\
    echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6 &&\
    echo "# added from startup_conoha_SSLH.sh" >> /etc/sysctl.conf &&\
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf &&\
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf &&\
    echo "# end " &&\
    sysctl -p &&\
    logging_INFO "ipv6 is disabled"

# ---------------------------------
# ADD SET any setup Below
# ---------------------------------

# ------------------------------
# Install docker 
# yum install is available...
# ------------------------------
yum install -y yum-utils device-mapper-persistent-data lvm2 &&\
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &&\
    yum install -y docker-ce &&\
    usermod -aG docker your-user $USERNAME&&\
    logging_INFO "docker-ce is installed."

# ------------------------------
# docker compose 
# ------------------------------
curl -L \
    "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)"\
     -o /usr/local/bin/docker-compose &&\
     chmod +x /usr/local/bin/docker-compose &&\
     logging_INFO "docker-compose is installed."

logging_INFO "docker-ce is installed."