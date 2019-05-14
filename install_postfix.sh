#!/bin/bash
## Script to create mailserver


# Getting informations about server and network
echo -e "Type your Domain (Ex.mydomain.com):  "; DOMAIN= read DOMAIN
echo -e "Type your IP (Ex.10.10.10.20): "; IP= read IP
echo -e "Type your NETWORK (Ex.10.0.0.0/16):  "; NETWORK= read NETWORK
echo -e "Type your HOSTNAME (Ex.myserver.mydomain.com):  "; HOSTNAME= read HOSTNAME


## Remove native version postfix
echo 'Removing old versions postfix'
#yum remove postfix -y

echo 'Add repo into centos repositories'
#cp post_repo.repo /etc/yum.repos.d/gf.repo
#yum clean all ; yum update ;

echo 'Instaling packages...'
#sudo yum install postfix3 - cyrus-sasl-plain mailx  cyrus-sasl-lib.x86_64 cyrus-sasl-md5.x86_64 cyrus-sasl.x86_64  cyrus-sasl.x86_64  postfix-perl-scripts opendkim wget opendmarc  -y

echo 'Enable services on boot'
#sudo systemctl enable postfix opendkim.service opendmarc

echo 'Enabling port 587 postfix...'
#sudo mv /etc/postfix/master.cf /etc/postfix/master.cf.bkp
#sudo cp ./master.cf /etc/postfix/

echo 'Configuring Postfix paramters...'
#sudo mv /etc/postfix/main.cf /etc/postfix/main.cf.bkp
#sudo cp ./main.cf /etc/postfix/main.cf

echo $DOMAIN $IP $NETWORK $HOSTNAME


printf "%s\n"  ' 
# Main config
queue_directory = /var/spool/postfix
mail_owner = postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
myhostname = '$HOSTNAME' 
myorigin = $mydomain
inet_interfaces = '$IP'
unknown_local_recipient_reject_code = 550
mynetworks = 127.0.0.0/8 '$IP'/32 '$NETWORK'
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
debug_peer_level = 2
debugger_command =
         PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
         ddd $daemon_directory/$process_name $process_id & sleep 5
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
inet_protocols = all
mydestination = $myhostname, localhost.$mydomain

#Configuration POSTIFIX AND CERTIFICATES 
smtp_sasl_auth_enable = yes
smtp_tls_security_level =
smtp_tls_key_file = /data/postfix/cert/smtpd.key
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_use_tls = yes
smtp_sasl_mechanism_filter =
smtp_tls_cert_file = /data/postfix/cert/smtpd.crt
smtp_tls_CAfile = /data/postfix/cert/cacert.pem
smtp_tls_security_level =
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination check_recipient_access
smtpd_sasl_auth_enable = yes
smtpd_sasl_authenticated_header = yes
smtpd_sasl_security_options =
broken_sasl_auth_clients = yes
smtpd_tls_auth_only = yes
smtpd_use_tls = yes
smtpd_tls_key_file = /data/postfix/cert/smtpd.key
smtpd_tls_cert_file = /data/postfix/cert/smtpd.crt
smtpd_tls_CAfile = /data/postfix/cert/cacert.pem
smtpd_tls_CApath = /data/postfix/cert
smtpd_tls_loglevel = 1
smtpd_helo_required = yes
smtpd_reject_unlisted_recipient = no
smtpd_data_restrictions = reject_unauth_pipelining
smtpd_tls_security_level = may
smtpd_sender_restrictions =
smtpd_client_restrictions = reject_unauth_pipelining
smtpd_tls_auth_only = yes
smtpd_banner = $myhostname ESMTP $mail_name
smtpd_sender_restrictions =

# MKDIM 
milter_protocol = 6
milter_default_action = accept
smtpd_milters = inet:localhost:8891, init:localhost:8893

'> /etc/postfix/main.cf 

echo 'Configuring certificates using Openssl...'
#sudo mkdir -p /data/postfix/cert/
#sudo openssl genrsa -des3 -rand /etc/hosts -out /data/postfix/cert/smtpd.key 1024
#sudo chmod 0600 /data/cert/smtpd.key
#sudo openssl req -new -key /data/postfix/cert/smtpd.key -out /data/postfix/cert/smtpd.csr 
#sudo openssl x509 -req -days 3650 -in /data/postfix/cert/smtpd.csr -signkey /data/postfix/cert/smtpd.key -out smtpd.crt
#sudo openssl rsa -in /data/postfix/cert/smtpd.key -out /data/postfix/cert/smtpd.key.unencrypt
#sudo mv -f /data/postfix/cert/smtpd.key.unencrypt  /data/postfix/cert/smtpd.key 
#sudo openssl req -new -x509 -extensions v3_ca -keyout /data/postfix/cert/cakey.pem -out /data/postfix/cert/cacert.pem -days 3650

echo 'Configuring OpenDkim...'
#sudo  cp /etc/opendkim.conf /etc/opendkim.conf.bkp 
#sudo cp ./opendkim.conf /etc/

printf "%s\n" '
PidFile    /var/run/opendkim/opendkim.pid
Mode    sv
Syslog    yes
SyslogSuccess    yes
LogWhy    yes
UserID    opendkim:opendkim
Socket    inet:8891@localhost
Umask    002
Canonicalization    relaxed/relaxed
Selector    default
MinimumKeyBits 1024
KeyTable    refile:/etc/opendkim/KeyTable
SigningTable    refile:/etc/opendkim/SigningTable
ExternalIgnoreList    refile:/etc/opendkim/TrustedHosts
InternalHosts    refile:/etc/opendkim/TrustedHosts
' > /etc/opendkim.conf


printf "%s\n" '
127.0.0.1
::1
'$NETWORK'
'$IP'/32
'$HOSTNAME'
'$DOMAIN'
' > /etc/opendkim/TrustedHosts

printf "%s\n" '
default._domainkey.'$DOMAIN' '$DOMAIN':default:/etc/opendkim/keys/default.private
' > /etc/opendkim/KeyTable 


printf "%s\n" '
*@'$DOMAIN' default._domainkey.'$DOMAIN'
' > /etc/opendkim/SigningTable

#Generating key opendkim
opendkim-genkey -D  /etc/opendkim/keys/ -d $DOMAIN  -s $DOMAIN
sudo chown -R opendkim  /etc/opendkim/keys/


echo 'Configuring OpenDmarc...'
#sudo  cp /etc/opendmarc.conf /etc/opendmarc.conf.bkp
#sudo  cp /etc/ignore.hosts  /etc/ignore.hosts.bkp

printf "%s\n" '
AuthservID ip-'$IP'
Socket inet:8893@localhost
SoftwareHeader true
SPFIgnoreResults true
SPFSelfValidate true
Syslog true
UMask 007
UserID opendmarc:mail
' > /etc/opendmarc.conf

printf "%s\n" '
localhost
127.0.0.0/8
'$NETWORK'
' > /etc/opendmarc/ignore.hosts

# STARTING SERVICES.
#systemctl start opendmarc opendkim.service postfix 

