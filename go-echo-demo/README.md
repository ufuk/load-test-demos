# go-echo-demo

Demo project for Go with Echo v5 framework.

## Prerequisites

- Go 1.27

## Run

```bash
go run main.go
```

## Endpoint

- **GET** `http://localhost:8080/demo/sum?value1=3&value2=5`
- **Response:** `{"result": 8}` (with 100ms artificial delay)
