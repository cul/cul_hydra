#!/bin/bash

# Set up symlinks if they don't exist.  The conditional checks ensure that this only runs if
# the volume is re-created.
[ ! -L /var/solr/hyacinth_hydra ] && ln -s /data/cul_hydra /var/solr/cul_hydra

precreate-core cul_hydra /template-cores/cul_hydra

# Start solr
solr-foreground
