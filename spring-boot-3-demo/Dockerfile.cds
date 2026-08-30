# Build stage
FROM maven:3-eclipse-temurin-25 AS builder
WORKDIR /app

# Build arguments for Maven (override via: docker build --build-arg MAVEN_ARGS="..." ...)
ARG MAVEN_ARGS=""

# Cache dependencies
COPY pom.xml .
RUN mvn dependency:resolve -B || true

# Build application package
COPY src ./src
RUN mvn clean package -DskipTests $MAVEN_ARGS

# CDS Training stage
FROM eclipse-temurin:25-jre AS trainer
WORKDIR /app

# Build arguments for training JVM flags (override via: docker build --build-arg TRAINER_JAVA_OPTS="..." ...)
ARG TRAINER_JAVA_OPTS="-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true"

COPY --from=builder /app/target/*.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --destination extracted
RUN cd extracted && java $TRAINER_JAVA_OPTS -XX:ArchiveClassesAtExit=application.jsa -Dspring.context.exit=onRefresh -jar app.jar

# Runtime stage
FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=trainer /app/extracted .

ENV JAVA_OPTS=""
EXPOSE 8080

USER 1001

ENTRYPOINT ["sh", "-c", "exec java -XX:SharedArchiveFile=application.jsa -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true $JAVA_OPTS -jar app.jar"]
