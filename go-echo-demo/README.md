# go-echo-demo

Demo project for Go with Echo v5 framework.

> 📊 For full multi-framework benchmark comparisons and load-testing matrix, see the root [README.md](../README.md).

## Prerequisites

- Go 1.27

## Run

### Local

```bash
go run main.go
```

### Docker

```bash
docker build -t go-echo-demo .
docker run -p 8080:8080 go-echo-demo
```

## Benchmark Endpoints

- **I/O-Bound:** `GET http://localhost:8080/benchmark/io-bound?value1=3&value2=5&delay=100`
- **CPU-Bound:** `GET http://localhost:8080/benchmark/cpu-bound?iterations=10000`
