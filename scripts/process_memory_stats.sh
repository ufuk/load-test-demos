#!/bin/bash

# Default values
process_id=""
container_id=""
total_seconds=30

# Parse named arguments
while getopts ":p:d:t:" opt; do
  case $opt in
  p)
    process_id=$OPTARG
    ;;
  d)
    container_id=$OPTARG
    ;;
  t)
    total_seconds=$OPTARG
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
  echo "Process ID (-p) or Docker Container ID (-d) is required."
  echo "Usage: $0 (-p <process_id> | -d <container_id>) [-t <total_seconds>]"
  exit 1
fi

declare -a mem_history=()
total_memory=0
max_memory=0
min_memory=999999999
count=0

get_memory_mb() {
  if [ -n "$process_id" ]; then
    rss=$(ps -o rss= -p "$process_id" 2>/dev/null | awk '{print int($1/1024)}')
    if [ -z "$rss" ]; then
      echo "0"
    else
      echo "$rss"
    fi
  elif [ -n "$container_id" ]; then
    raw=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_id" 2>/dev/null | awk '{print $1}')
    if [[ "$raw" =~ ([0-9.]+)GiB ]]; then
      awk -v v="${BASH_REMATCH[1]}" 'BEGIN {printf "%.0f\n", v * 1024}'
    elif [[ "$raw" =~ ([0-9.]+)MiB ]]; then
      awk -v v="${BASH_REMATCH[1]}" 'BEGIN {printf "%.0f\n", v}'
    elif [[ "$raw" =~ ([0-9.]+)kB ]]; then
      awk -v v="${BASH_REMATCH[1]}" 'BEGIN {printf "%.0f\n", v / 1024}'
    else
      echo "0"
    fi
  fi
}

echo "Monitoring memory for ${total_seconds}s..."

for ((i = 0; i < total_seconds; i++)); do
  mem=$(get_memory_mb)
  mem_history+=("$mem")

  total_memory=$((total_memory + mem))
  count=$((count + 1))

  if [ "$mem" -gt "$max_memory" ]; then
    max_memory=$mem
  fi
  if [ "$mem" -lt "$min_memory" ]; then
    min_memory=$mem
  fi

  printf "Sec %2ds: %4d MB\n" "$i" "$mem"
  sleep 1
done

if [ "$count" -eq 0 ]; then
  count=1
fi
average_memory=$((total_memory / count))

# Sparkline characters:   ▂ ▃ ▄ ▅ ▆ ▇ █
spark_chars=(" " "▂" "▃" "▄" "▅" "▆" "▇" "█")
sparkline=""
range=$((max_memory - min_memory))
if [ "$range" -le 0 ]; then
  range=1
fi

for m in "${mem_history[@]}"; do
  idx=$(((m - min_memory) * 7 / range))
  if [ "$idx" -lt 0 ]; then idx=0; fi
  if [ "$idx" -gt 7 ]; then idx=7; fi
  sparkline+="${spark_chars[$idx]}"
done

echo ""
echo "================ Memory Statistics ================"
if [ -n "$process_id" ]; then
  echo "Target: Process PID $process_id"
else
  echo "Target: Docker Container $container_id"
fi
echo "Duration: ${total_seconds}s"
echo "Min Memory : ${min_memory} MB"
echo "Avg Memory : ${average_memory} MB"
echo "Max Memory : ${max_memory} MB"
echo "Sparkline  : [${sparkline}]"
echo "==================================================="
echo ""
echo "Memory Timeline Chart:"
max_bar_width=40
for ((i = 0; i < count; i++)); do
  m="${mem_history[$i]}"
  if [ "$max_memory" -gt 0 ]; then
    bar_len=$((m * max_bar_width / max_memory))
  else
    bar_len=0
  fi
  bar=""
  for ((b = 0; b < bar_len; b++)); do
    bar+="█"
  done
  printf "[%2ds] %4d MB | %s\n" "$i" "$m" "$bar"
done
