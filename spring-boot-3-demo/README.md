# spring-boot-3-demo

Demo project for Spring Boot 3.5.x, showcasing standard JIT, Class Data Sharing (CDS), and GraalVM Native Image
deployments.

> 📊 For full multi-framework benchmark comparisons and load-testing matrix, see the root [README.md](../README.md).

## Prerequisites

- Java 25 (Standard JVM runs)
- Docker (For CDS and Native Image builds)

## 🚀 Running the Application

### 1. Standard JVM (Local)

```bash
./mvnw spring-boot:run
```

### 2. Standard JVM (Docker)

```bash
docker build -t spring-boot-3-demo .
docker run -p 8080:8080 -e JAVA_OPTS="-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true" spring-boot-3-demo
```

### 3. Class Data Sharing (CDS)

CDS significantly improves startup times by caching parsed class metadata.

```bash
# Generate the CDS archive (training run)
docker run --rm --entrypoint java -v $(pwd)/logs:/app/logs spring-boot-3-demo -XX:ArchiveClassesAtExit=app-cds.jsa -jar app.jar --spring.context.exit-on-refresh=true

# Run with CDS enabled
docker run -p 8080:8080 -e JAVA_OPTS="-XX:SharedArchiveFile=app-cds.jsa" spring-boot-3-demo
```

### 4. GraalVM Native Image

Compiles the application Ahead-of-Time (AOT) to a standalone executable for instant startup and low memory footprint.

**Native Platform Threads:**

```bash
docker build -f Dockerfile.native -t spring-boot-3-native .
docker run -p 8080:8080 spring-boot-3-native
```

**Native Virtual Threads:**
*(Virtual threads must be evaluated at AOT build-time due to GraalVM's Closed-World Assumption)*

```bash
docker build -f Dockerfile.native --build-arg MAVEN_ARGS="-DskipTests -Dspring-boot.aot.jvmArguments=-Dspring.threads.virtual.enabled=true" -t spring-boot-3-native-vt .
docker run -p 8080:8080 spring-boot-3-native-vt
```

## 🧪 Benchmark Endpoints

- **I/O-Bound:** `GET http://localhost:8080/benchmark/io-bound?value1=3&value2=5&delay=100`
- **CPU-Bound:** `GET http://localhost:8080/benchmark/cpu-bound?iterations=10000`
