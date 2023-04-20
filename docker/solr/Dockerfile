FROM solr:6.3.0

WORKDIR /data

# Set up template cores in image

COPY --chown=solr:solr './solr-cores/development' /template-cores/development
RUN echo 'name=development' > /template-cores/development/core.properties

# When image runs, the command below will copy template cores to final location (on mounted docker
#  volume) if they don't already exist, and then will start solr.

CMD [ ! -d /opt/solr/server/solr/development ] && cp -pr /template-cores/development /data/development && \
    ln -s /data/development /opt/solr/server/solr/development && \
    solr-foreground
