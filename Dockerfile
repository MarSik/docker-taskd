FROM alpine:latest
MAINTAINER Martin Sivak (mars@montik.net)

# Install necessary stuff
RUN apk -U --no-progress upgrade && \
  apk -U --no-progress add taskd taskd-pki certbot

# Import build and startup script
ADD run.sh /
ADD createUser /bin/

# Set the data location
ENV TASKDDATA "/home"
ENV TASKD_ORGANIZATION "Public"
ENV TASKD_USERNAME "Bob"


# Configure container
VOLUME ["${TASKDDATA}"]
VOLUME /etc/letsencrypt

EXPOSE 53589
EXPOSE 80

ENTRYPOINT ["/run.sh"]
