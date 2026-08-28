# spring-boot-2-demo

Demo project for Spring Boot 2.7.x.

> 📊 For full multi-framework benchmark comparisons and load-testing matrix, see the root [README.md](../README.md).

## Prerequisites

- Java 21

## Run

### Local

```bash
./mvnw spring-boot:run
```

### Docker

```bash
docker build -t spring-boot-2-demo .
docker run -p 8080:8080 -e JAVA_OPTS="-XX:+UseG1GC" spring-boot-2-demo
```

## Benchmark Endpoints

- **I/O-Bound:** `GET http://localhost:8080/benchmark/io-bound?value1=3&value2=5&delay=100`
- **CPU-Bound:** `GET http://localhost:8080/benchmark/cpu-bound?iterations=10000`
