#!/bin/bash

# Install Fedora if it has not already been installed.  The check below ensure that this
# installation only runs once (whenever the /opt/fedora volume is re-created).
if [ ! -f /opt/fedora/tomcat/bin/catalina.sh ]; then
  java -jar /opt/fcrepo-installer.jar /opt/install.properties
  echo 'Done running installer jar...'
fi

cp /opt/deny-unallowed-file-resolution.xml /opt/fedora/data/fedora-xacml-policies/repository-policies/deny-unallowed-file-resolution.xml
/opt/fedora/tomcat/bin/catalina.sh run
