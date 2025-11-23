#!/bin/bash

# Set up symlinks if they don't exist.  The conditional checks ensure that this only runs if
# the volume is re-created.
[ ! -L /var/solr/ac ] && ln -s /data/ac /var/solr/ac

precreate-core ac /template-cores/ac

# Start solr
solr-foreground
