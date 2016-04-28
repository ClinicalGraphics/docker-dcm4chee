#
# DCM4CHEE - Open source picture archive and communications server (PACS)
#
FROM ubuntu:15.04
MAINTAINER K. van Golen <k.vangolen@clinicalgraphics.com>

# install cURL, zip, MySQL server and OpenJDK 6
RUN apt-get update
# the env var is temporarily set so that mysql-server uses a blank root password
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl zip mysql-server openjdk-6-jdk

# create DCM4CHEE home
ENV DCM4CHEE_HOME /var/local/dcm4chee
RUN mkdir -p $DCM4CHEE_HOME
WORKDIR $DCM4CHEE_HOME

# create workdir 
ADD stage /stage

# Download the binary package for DCM4CHEE
RUN curl -sLG http://downloads.sourceforge.net/project/dcm4che/dcm4chee/2.18.1/dcm4chee-2.18.1-mysql.zip > /stage/dcm4chee-2.18.1-mysql.zip
RUN unzip -q /stage/dcm4chee-2.18.1-mysql.zip
ENV DCM_DIR $DCM4CHEE_HOME/dcm4chee-2.18.1-mysql

# Download the binary package for JBoss
RUN curl -sLG http://downloads.sourceforge.net/project/jboss/JBoss/JBoss-4.2.3.GA/jboss-4.2.3.GA-jdk6.zip > /stage/jboss-4.2.3.GA-jdk6.zip
RUN unzip -q /stage/jboss-4.2.3.GA-jdk6.zip
ENV JBOSS_DIR $DCM4CHEE_HOME/jboss-4.2.3.GA-jdk6

# Download the Audit Record Repository (ARR) package
RUN curl -sLG http://downloads.sourceforge.net/project/dcm4che/dcm4chee-arr/3.0.11/dcm4chee-arr-3.0.11-mysql.zip > /stage/dcm4chee-arr-3.0.11-mysql.zip
RUN unzip -q /stage/dcm4chee-arr-3.0.11-mysql.zip
ENV ARR_DIR $DCM4CHEE_HOME/dcm4chee-arr-3.0.11-mysql

# Copy files from JBoss to dcm4chee
RUN $DCM_DIR/bin/install_jboss.sh jboss-4.2.3.GA

# Copy files from the Audit Record Repository (ARR) to dcm4chee
RUN $DCM_DIR/bin/install_arr.sh dcm4chee-arr-3.0.11-mysql

# Install and set up MySQL
RUN /bin/bash /stage/mysql.bash

# Patch the JPEGImageEncoder issue for the WADO service
RUN sed -e "s/value=\"com.sun.media.imageioimpl.plugins.jpeg.CLibJPEGImageWriter\"/value=\"com.sun.image.codec.jpeg.JPEGImageEncoder\"/g" < $DCM_DIR/server/default/conf/xmdesc/dcm4chee-wado-xmbean.xml > dcm4chee-wado-xmbean.xml
RUN mv dcm4chee-wado-xmbean.xml $DCM_DIR/server/default/conf/xmdesc/dcm4chee-wado-xmbean.xml

# Update environment variables
RUN echo "\
JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64\n\
PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\
" > /etc/environment

# web UI port
EXPOSE 8080
# DICOM port
EXPOSE 11112

CMD ["/bin/bash", "/stage/start.bash"]
