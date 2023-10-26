FROM solr:8.11.2

WORKDIR /data

# Set up template cores in image

COPY --chown=solr:solr './solr-cores/ac' /template-cores/ac
RUN echo 'name=ac' > /template-cores/ac/core.properties

# When image runs, the command below will copy template cores to final location (on mounted docker
#  volume) if they don't already exist, and then will start solr.

CMD [ ! -d /var/solr/data/ac ] && cp -pr /template-cores/ac /data/ac && \  
    ln -s /data/ac /var/solr/data/ac && \
    solr-foreground
