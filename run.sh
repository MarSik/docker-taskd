#! /bin/sh
#
# run.sh
# Copyright (C) 2015 Óscar García Amor <ogarcia@connectical.com>
#               2021 Martin Sivak <mars@montik.net>
# Distributed under terms of the MIT license.
#

# If no config file found, do initial config
if ! test -e ${TASKDDATA}/config; then

  # Create directories for log and certs
  mkdir -p ${TASKDDATA}/log ${TASKDDATA}/pki

  # Init taskd and configure log
  taskd init
  taskd config --force log ${TASKDDATA}/log/taskd.log

  if [ "$EMAIL" != "" ]; then
    # Use letsencrypt to get server certificates
    certbot certonly -n --standalone --cert-name ${HOSTNAME} --agree-tos --email ${EMAIL}

    # Configure taskd to use this newly generated certificates
    taskd config --force server.cert /etc/letsencrypt/live/$HOSTNAME/fullchain.pem
    taskd config --force server.key /etc/letsencrypt/live/$HOSTNAME/privkey.pem
  fi

  # And finally set taskd to listen in default port
  taskd config --force server 0.0.0.0:53589

  #
  # Generate self signed CA for client authentication
  #

  # Copy tools for certificates generation and generate it
  cp /usr/share/taskd/pki/generate.ca /usr/share/taskd/pki/generate.client ${TASKDDATA}/pki

  cd ${TASKDDATA}/pki
  # Do not overwrite vars file if already mounted or injected
  if ! test -e ${TASKDDATA}/pki/vars; then
    cp /usr/share/taskd/pki/vars ${TASKDDATA}/pki
    echo "CN=$HOSTNAME" >> ${TASKDDATA}/pki/vars
  fi

  echo
  echo "Generating the client certificate authority"
  echo
  ./generate.ca
  cd /

  # Create first user
  /bin/createUser
fi

if [ -e "/etc/letsencrypt/live/${HOSTNAME}/privkey.pem" ]; then
  # Renew certificates
  certbot renew -n
fi

# Exec CMD or taskd by default if nothing present
if [ $# -gt 0 ];then
  exec "$@"
else
  exec taskd server --data ${TASKDDATA}
fi
