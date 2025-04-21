# load-test-demos

Install [k6](https://k6.io/docs/) before run tests:

```bash
brew install k6
```

Run load test while monitoring memory usage:

```bash
./run-load-test.sh -p <process_id> -s <k6_script_file_name> -c <concurrent_user_count> -t <total_seconds>

# For example:
# ./run_load_test.sh -p 46852 -s k6-script-demo-sum-endpoint.js -c 100 -t 30
```

To monitor a process' memory usage, you can run process_memory_stats.sh individually:

```bash
./process_memory_stats.sh -p <process_id> -t <total_seconds>

# For example:
# ./process_memory_stats.sh -p 46852 -t 30
```

To start a k6 load test script with a certain amount of concurrent users for a few seconds individually:

```bash
k6 run --vus <concurrent_user_count> --duration <total_seconds>s <k6_script_file_name>

# For example:
# k6 run --vus 100 --duration 30s k6-script-demo-sum-endpoint.js
```
