FROM solr:9.8.1

WORKDIR /data

COPY ./setup-and-start.sh .

COPY --chown=solr:solr './solr_cores/ac-solr-9' /template-cores/ac
RUN echo 'name=ac' > /template-cores/ac/core.properties

CMD /bin/bash ./setup-and-start.sh
