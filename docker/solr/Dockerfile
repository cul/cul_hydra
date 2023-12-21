FROM solr:8.11.2

WORKDIR /data

COPY ./setup-and-start.sh .

COPY --chown=solr:solr './solr_cores/cul-hydra-solr-8' /template-cores/cul_hydra
RUN echo 'name=cul_hydra' > /template-cores/cul_hydra/core.properties

CMD /bin/bash ./setup-and-start.sh
