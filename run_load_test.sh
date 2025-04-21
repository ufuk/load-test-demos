#!/bin/bash

# Default values
process_id=""
k6_script_file_name=""
total_seconds=30
concurrent_user_count=100

# Parse named arguments
while getopts ":p:t:c:s:" opt; do
    case $opt in
        p)
            process_id=$OPTARG
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

# Check if process ID is provided
if [ -z "$process_id" ]; then
    echo "Process ID is required. Usage: $0 -p <process_id> -s <k6_script_file_name> [-c <concurrent_user_count>] [-t <total_seconds>]"
    exit 1
fi

# Check if k6 script file name is provided
if [ -z "$k6_script_file_name" ]; then
    echo "k6 script file name is required. Usage: $0 -p <process_id> -s <k6_script_file_name> [-c <concurrent_user_count>] [-t <total_seconds>]"
    exit 1
fi

# Start memory usage monitoring with custom script
memory_stats_report_file_name="run-reports/memory-usage-$process_id.log"
if [ -e "$memory_stats_report_file_name" ]; then
    rm "$memory_stats_report_file_name"
    echo "Former memory monitoring report for process cleared: '$memory_stats_report_file_name'"
fi
./process_memory_stats.sh -p "$process_id" -t "$total_seconds" >> "$memory_stats_report_file_name" &
pid_process_memory_stats=$!
echo "Memory usage monitoring started with PID $pid_process_memory_stats"

# Run load test with k6
k6 run --vus "$concurrent_user_count" --duration "$total_seconds"s "$k6_script_file_name" &
pid_k6=$!
echo "k6 started with PID $pid_process_memory_stats"

wait $pid_k6
wait $pid_process_memory_stats

echo ""
tail -n 3 "$memory_stats_report_file_name"
echo "Check '$memory_stats_report_file_name' for detailed report."
