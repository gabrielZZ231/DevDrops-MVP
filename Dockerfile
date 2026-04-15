FROM maven:3.9.11-eclipse-temurin-8 AS build
WORKDIR /workspace

COPY pom.xml ./

# Legacy dependency not available in Maven Central.
RUN curl -fsSL -o /tmp/jsf-facelets-1.1.15.B1.jar "https://repository.jboss.org/nexus/repository/thirdparty-releases/com/sun/facelets/jsf-facelets/1.1.15.B1/jsf-facelets-1.1.15.B1.jar" \
        && mvn -B -q install:install-file \
            -DgroupId=com.sun.facelets \
            -DartifactId=jsf-facelets \
            -Dversion=1.1.15.B1 \
            -Dpackaging=jar \
            -Dfile=/tmp/jsf-facelets-1.1.15.B1.jar \
        && rm -f /tmp/jsf-facelets-1.1.15.B1.jar

COPY src ./src
RUN mvn -B -DskipTests clean package

FROM eclipse-temurin:8-jre AS runtime
ARG JBOSS_VERSION=5.1.0.GA
ENV JBOSS_HOME=/opt/jboss/jboss-5.1.0.GA

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/jboss \
    && curl -fsSL -o /tmp/jboss.zip "https://downloads.sourceforge.net/project/jboss/JBoss/JBoss-${JBOSS_VERSION}/jboss-${JBOSS_VERSION}.zip" \
    && unzip -q /tmp/jboss.zip -d /opt/jboss \
    && rm -f /tmp/jboss.zip

COPY --from=build /workspace/target/devdrops.war ${JBOSS_HOME}/server/default/deploy/devdrops.war
COPY --from=build /root/.m2/repository/org/postgresql/postgresql/42.2.27.jre7/postgresql-42.2.27.jre7.jar ${JBOSS_HOME}/server/default/lib/
COPY --from=build /root/.m2/repository/com/sun/facelets/jsf-facelets/1.1.15.B1/jsf-facelets-1.1.15.B1.jar ${JBOSS_HOME}/server/default/lib/

COPY docker/jboss/entrypoint.sh /opt/devdrops/entrypoint.sh
RUN chmod +x /opt/devdrops/entrypoint.sh

EXPOSE 8080 8009 1099
ENTRYPOINT ["/opt/devdrops/entrypoint.sh"]
