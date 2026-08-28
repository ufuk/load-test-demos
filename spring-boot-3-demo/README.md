# spring-boot-3-demo

Demo project for Spring Boot 3.5.x.

> 📊 For full multi-framework benchmark comparisons and load-testing matrix, see the root [README.md](../README.md).

## Prerequisites

- Java 25

## Run

### Local

```bash
./mvnw spring-boot:run
```

### Docker

```bash
docker build -t spring-boot-3-demo .
docker run -p 8080:8080 -e JAVA_OPTS="-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true" spring-boot-3-demo
```

## Benchmark Endpoints

- **I/O-Bound:** `GET http://localhost:8080/benchmark/io-bound?value1=3&value2=5&delay=100`
- **CPU-Bound:** `GET http://localhost:8080/benchmark/cpu-bound?iterations=10000`
