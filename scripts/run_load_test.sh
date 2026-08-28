#!/bin/bash

# Default values
process_id=""
container_id=""
k6_script_file_name="k6/io_bound_test.js"
total_seconds=30
concurrent_user_count=100
summary_output_file=""

# Parse named arguments
while getopts ":p:d:t:c:s:o:" opt; do
  case $opt in
  p)
    process_id=$OPTARG
    ;;
  d)
    container_id=$OPTARG
    ;;
  s)
    k6_script_file_name=$OPTARG
    ;;
  c)
    concurrent_user_count=$OPTARG
    ;;
  t)
    total_seconds=$OPTARG
    ;;
  o)
    summary_output_file=$OPTARG
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
done

if [ -z "$process_id" ] && [ -z "$container_id" ]; then
  echo "Target is required. Usage: $0 (-p <process_id> | -d <container_id>) [-s <k6_script>] [-c <vus>] [-t <seconds>] [-o <summary_file>]"
  exit 1
fi

if [ ! -f "$k6_script_file_name" ]; then
  echo "k6 script '$k6_script_file_name' not found."
  exit 1
fi

temp_report=$(mktemp /tmp/memory_usage_report.XXXXXX)
temp_k6_summary=$(mktemp /tmp/k6_summary.XXXXXX)
trap 'rm -f "$temp_report" "$temp_k6_summary"' EXIT

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start memory monitoring
if [ -n "$process_id" ]; then
  "$SCRIPT_DIR/process_memory_stats.sh" -p "$process_id" -t "$total_seconds" >"$temp_report" &
else
  "$SCRIPT_DIR/process_memory_stats.sh" -d "$container_id" -t "$total_seconds" >"$temp_report" &
fi
pid_process_memory_stats=$!
echo "Memory usage monitoring started (PID: $pid_process_memory_stats)"

# Run load test with k6
k6 run --summary-export "$temp_k6_summary" --vus "$concurrent_user_count" --duration "${total_seconds}s" "$k6_script_file_name" &
pid_k6=$!
echo "k6 started (PID: $pid_k6)"

wait $pid_k6 2>/dev/null || true
wait $pid_process_memory_stats 2>/dev/null || true

echo ""
echo "==================================================="
cat "$temp_report"
echo "==================================================="

# Parse summary values if requested
if [ -n "$summary_output_file" ]; then
  min_ram=$(grep "Min Memory" "$temp_report" | awk '{print $(NF-1)}')
  avg_ram=$(grep "Avg Memory" "$temp_report" | awk '{print $(NF-1)}')
  max_ram=$(grep "Max Memory" "$temp_report" | awk '{print $(NF-1)}')
  sparkline=$(grep "Sparkline" "$temp_report" | sed -E 's/.*\[(.*)\].*/\1/')

  rps="0"
  p95="0.0"
  errors="0.0%"
  if [ -s "$temp_k6_summary" ]; then
    read -r rps p95 errors <<<"$(python3 -c "
import json
try:
    with open('$temp_k6_summary') as f:
        d = json.load(f)
        m = d.get('metrics', {})
        rate = m.get('http_reqs', {}).get('rate', 0.0)
        p95_val = m.get('http_req_duration', {}).get('p(95)', 0.0)
        fail_rate = m.get('http_req_failed', {}).get('value', 0.0)
        print(f'{rate:.0f} {p95_val:.1f} {fail_rate*100:.1f}%')
except Exception:
    print('0 0.0 0.0%')
")"
  fi

  echo "min_ram=\"$min_ram\"" >"$summary_output_file"
  echo "avg_ram=\"$avg_ram\"" >>"$summary_output_file"
  echo "max_ram=\"$max_ram\"" >>"$summary_output_file"
  echo "sparkline=\"$sparkline\"" >>"$summary_output_file"
  echo "rps=\"$rps\"" >>"$summary_output_file"
  echo "p95=\"$p95\"" >>"$summary_output_file"
  echo "errors=\"$errors\"" >>"$summary_output_file"
fi
