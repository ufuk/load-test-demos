# spring-boot-4-demo

Demo project for Spring Boot 4.1.x, highlighting the evolution of AOT processing, Scripted CDS, and GraalVM Native Image generation.

> 📊 For full multi-framework benchmark comparisons and load-testing matrix, see the root [README.md](../README.md).

## Prerequisites

- Java 26 (Standard JVM runs)
- Docker (For CDS and Native Image builds)

## 🚀 Running the Application

### 1. Standard JVM (Local)
```bash
./mvnw spring-boot:run
```

### 2. Standard JVM (Docker)
```bash
docker build -t spring-boot-4-demo .
docker run -p 8080:8080 -e JAVA_OPTS="-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true" spring-boot-4-demo
```

### 3. AOT & Scripted CDS (Spring Boot 4.x feature)
Spring Boot 4 introduced pre-packaged CDS training scripts and enhanced AOT context generation.
```bash
# Run the built-in training script to generate application.jsa
docker run --rm --entrypoint /bin/bash -v $(pwd)/logs:/app/logs spring-boot-4-demo -c "java -Djarmode=tools -jar app.jar extract && cd app && java -XX:ArchiveClassesAtExit=application.jsa -Dspring.context.exit-on-refresh=true -jar app.jar"

# Run with the CDS archive
docker run -p 8080:8080 -e JAVA_OPTS="-XX:SharedArchiveFile=app/application.jsa" --entrypoint java spring-boot-4-demo -jar app/app.jar
```

### 4. GraalVM Native Image
Ahead-of-Time compilation for maximum efficiency in microservices. 

**Native Platform Threads:**
```bash
docker build -f Dockerfile.native -t spring-boot-4-native .
docker run -p 8080:8080 spring-boot-4-native
```

**Native Virtual Threads:**
*(Virtual threads must be explicitly enabled during the AOT phase)*
```bash
docker build -f Dockerfile.native --build-arg MAVEN_ARGS="-DskipTests -Dspring-boot.aot.jvmArguments=-Dspring.threads.virtual.enabled=true" -t spring-boot-4-native-vt .
docker run -p 8080:8080 spring-boot-4-native-vt
```

## 🧪 Benchmark Endpoints

- **I/O-Bound:** `GET http://localhost:8080/benchmark/io-bound?value1=3&value2=5&delay=100`
- **CPU-Bound:** `GET http://localhost:8080/benchmark/cpu-bound?iterations=10000`
