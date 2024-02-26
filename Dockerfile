FROM busybox AS unpack
WORKDIR /unpack

#Arguments definition
ARG KETTLE_ZIP_FILE=pdi-ce-9.4.0.0-343.zip

COPY ./predownloaded/$KETTLE_ZIP_FILE /
RUN echo "$KETTLE_ZIP_FILE"


RUN unzip /$KETTLE_ZIP_FILE && \
    rm -f /$KETTLE_ZIP_FILE && \
	find ./data-integration -name "*.bat" -type f -delete && \
	rm -rf ./data-integration/docs && \
	rm -rf ./data-integration/libswt/win64 && \
	rm -rf "./data-integration/Data Service JDBC Driver"

FROM  eclipse-temurin:17-jre-jammy

# Configs directories and users for pentaho 
RUN mkdir /pentaho && \
  mkdir /home/pentaho && \
  mkdir /home/pentaho/.kettle && \
  mkdir /home/pentaho/.aws && \
  groupadd -r pentaho && \
  useradd -r -g pentaho -p $(perl -e'print crypt("pentaho", "salt")' ) -G sudo pentaho && \
  chown -R pentaho.pentaho /pentaho && \ 
  chown -R pentaho.pentaho /home/pentaho
 

COPY --from=unpack --chown=pentaho:pentaho /unpack/data-integration /pentaho/data-integration
WORKDIR /pentaho/data-integration

# Adds connections config files
ADD --chown=pentaho:pentaho scripts/* ./

# Changes spoon.sh to expose memory to env-vars
RUN sed -i \
  's/-Xmx[0-9]\+m/-Xmx\$\{_RUN_XMX:-2048\}m/g' spoon.sh 

ENV PDI_HOME /pentaho/data-integration
ENV SKIP_WEBKITGTK_CHECK=1

USER pentaho

ENTRYPOINT ["/pentaho/data-integration/run.sh"]
