# load-test-demos

A benchmark and load-testing demonstration comparing memory usage and response performance across different frameworks
and runtimes:

- [go-echo-demo](go-echo-demo): Go 1.27 with Echo v5
- [spring-boot-2-demo](spring-boot-2-demo): Spring Boot 2.7.x (Java 21)
- [spring-boot-3-demo](spring-boot-3-demo): Spring Boot 3.5.x (Java 25)
- [spring-boot-4-demo](spring-boot-4-demo): Spring Boot 4.1.x (Java 26)

All demo services expose a common endpoint: `GET /demo/sum?value1=3&value2=5` which returns `{"result": 8}` after a
100ms artificial delay.

## Prerequisites

Install [k6](https://k6.io/docs/) before running tests:

```bash
brew install k6
```

## Running Load Tests

Run the load test while monitoring memory usage:

```bash
./run_load_test.sh -p <process_id> -s <k6_script_file_name> -c <concurrent_user_count> -t <total_seconds>

# For example:
# ./run_load_test.sh -p 46852 -s k6-script-demo-sum-endpoint.js -c 100 -t 30
```

## Running Individual Scripts

To monitor a process' memory usage individually:

```bash
./process_memory_stats.sh -p <process_id> -t <total_seconds>

# For example:
# ./process_memory_stats.sh -p 46852 -t 30
```

To start a k6 load test script individually:

```bash
k6 run --vus <concurrent_user_count> --duration <total_seconds>s <k6_script_file_name>

# For example:
# k6 run --vus 100 --duration 30s k6-script-demo-sum-endpoint.js
```
