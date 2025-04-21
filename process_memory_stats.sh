#!/bin/bash

# Default values
process_id=""
total_seconds=30

# Parse named arguments
while getopts ":p:t:" opt; do
    case $opt in
        p)
            process_id=$OPTARG
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
    echo "Process ID is required. Usage: $0 -p <process_id> [-t <total_seconds>]"
    exit 1
fi

# Variables for calculations
total_memory=0
max_memory=-1
min_memory=-1
count=0

# Run the command for the specified number of seconds
for ((i = 0; i < total_seconds; i++)); do
    memory_usage=$(ps -o rss= -p "$process_id" | awk '{print int($1/1024)}')
    echo "Memory usage at second $i: ${memory_usage}MB"

    # Update variables for calculations
    total_memory=$((total_memory + memory_usage))

    # Update max and min memory
    if [ "$max_memory" -eq -1 ] || [ "$memory_usage" -gt "$max_memory" ]; then
        max_memory=$memory_usage
    fi

    if [ "$min_memory" -eq -1 ] || [ "$memory_usage" -lt "$min_memory" ]; then
        min_memory=$memory_usage
    fi

    sleep 1
    count=$((count + 1))
done

# Calculate average memory usage
average_memory=$((total_memory / count))

# Print results
echo ""
echo "Memory Stats for PID $process_id:"
echo "==========================="
echo "min=${min_memory}MB, avg=${average_memory}MB, max=${max_memory}MB"
