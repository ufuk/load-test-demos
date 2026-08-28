# Build stage
FROM maven:3-eclipse-temurin-26 AS builder
WORKDIR /app

# Cache dependencies
COPY pom.xml .
RUN mvn dependency:resolve -B || true

# Build application package
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:26-jre
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

ENV JAVA_OPTS=""
EXPOSE 8080

USER 1001

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
