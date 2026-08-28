# spring-boot-4-demo

Demo project for Spring Boot 4.1.x.

## Prerequisites

- Java 26

## Run

```bash
./mvnw spring-boot:run
```

## Endpoint

- **GET** `http://localhost:8080/demo/sum?value1=3&value2=5`
- **Response:** `{"result": 8}` (with 100ms artificial delay)
