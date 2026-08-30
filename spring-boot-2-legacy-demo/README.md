# spring-boot-2-legacy-demo

Demo project for Spring Boot 2.0.x (2.0.9.RELEASE) on Java 8.

> 📊 For full multi-framework benchmark comparisons and load-testing matrix, see the root [README.md](../README.md).

## Prerequisites

- Java 8

## Run

### Local

```bash
./mvnw spring-boot:run
```

### Docker

```bash
docker build -t spring-boot-2-legacy-demo .
docker run -p 8080:8080 spring-boot-2-legacy-demo
```

## Benchmark Endpoints

- **I/O-Bound:** `GET http://localhost:8080/benchmark/io-bound?value1=3&value2=5&delay=100`
- **CPU-Bound:** `GET http://localhost:8080/benchmark/cpu-bound?iterations=10000`
