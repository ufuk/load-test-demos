#!/bin/bash

set -e

# Default settings
test_type="io"
duration=30
vus=100
cpus="2"
memory="512m"
profile="all" # "all", "quick", "tuning"

usage() {
  echo "Usage: $0 [-t io|cpu] [-v <vus: 100|1000>] [-d <seconds>] [-c <cpus>] [-m <memory>] [-p all|quick|tuning]"
  echo "Example:"
  echo "  $0 -v 100 -d 30      # Baseline concurrency (100 VUs)"
  echo "  $0 -v 1000 -d 30     # High concurrency scale test (1000 VUs)"
  exit 1
}

while getopts ":t:d:v:c:m:p:h" opt; do
  case $opt in
  t) test_type=$OPTARG ;;
  d) duration=$OPTARG ;;
  v) vus=$OPTARG ;;
  c) cpus=$OPTARG ;;
  m) memory=$OPTARG ;;
  p) profile=$OPTARG ;;
  h) usage ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    usage
    ;;
  esac
done

if [ "$test_type" == "cpu" ]; then
  k6_script="k6/cpu_bound_test.js"
else
  k6_script="k6/io_bound_test.js"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cleanup() {
  echo ""
  echo ">>> Cleaning up containers..."
  docker rm -f benchmark-runner 2>/dev/null || true
  exit 1
}
trap cleanup SIGINT SIGTERM

echo "========================================================================================="
echo "                          LOAD TEST BENCHMARK SUITE RUNNER                               "
echo "========================================================================================="
echo "Workload   : $vus VUs | Duration: ${duration}s | Test: $test_type ($k6_script)"
echo "Resources  : CPU Limit: $cpus cores | RAM Limit: $memory"
echo "Profile    : $profile"
echo "========================================================================================="

# Build all required docker images first
build_image() {
  local dir=$1
  local tag=$2
  local dockerfile=${3:-Dockerfile}
  shift 3 2>/dev/null || true
  local extra_args=("$@")
  echo -n "Building image $tag ($dockerfile)... "
  docker build -f "$ROOT_DIR/$dir/$dockerfile" "${extra_args[@]}" -t "$tag" "$ROOT_DIR/$dir" >/dev/null
  echo "DONE"
}

echo ""
echo "[1/3] Building container images..."
build_image "go-echo-demo" "load-test-go-echo:latest"
build_image "spring-boot-2-legacy-demo" "load-test-spring-boot-2-legacy:latest"
build_image "spring-boot-2-demo" "load-test-spring-boot-2:latest"
build_image "spring-boot-3-demo" "load-test-spring-boot-3:latest"
build_image "spring-boot-3-demo" "load-test-spring-boot-3:cds" "Dockerfile.cds"
build_image "spring-boot-3-demo" "load-test-spring-boot-3:native" "Dockerfile.native"
build_image "spring-boot-3-demo" "load-test-spring-boot-3:native-virtual" "Dockerfile.native" --build-arg MAVEN_ARGS="-DskipTests -Dspring-boot.aot.jvmArguments=-Dspring.threads.virtual.enabled=true"
build_image "spring-boot-4-demo" "load-test-spring-boot-4:latest"
build_image "spring-boot-4-demo" "load-test-spring-boot-4:aot" "Dockerfile.aot"
build_image "spring-boot-4-demo" "load-test-spring-boot-4:native" "Dockerfile.native"
build_image "spring-boot-4-demo" "load-test-spring-boot-4:native-virtual" "Dockerfile.native" --build-arg MAVEN_ARGS="-DskipTests -Djava.version=25 -Dspring-boot.aot.jvmArguments=-Dspring.threads.virtual.enabled=true"

# Matrix of benchmark test configurations:
# name | image | java_opts
declare -a configs=()

configs+=("Spring Boot 2.0 (Legacy Java 8)|load-test-spring-boot-2-legacy:latest|")
configs+=("Spring Boot 2.7 (Platform Threads)|load-test-spring-boot-2:latest|")

if [ "$profile" == "all" ] || [ "$profile" == "quick" ]; then
  configs+=("Spring Boot 3.5 (Platform Threads)|load-test-spring-boot-3:latest|")
fi

if [ "$profile" == "all" ] || [ "$profile" == "quick" ] || [ "$profile" == "tuning" ]; then
  configs+=("Spring Boot 3.5 (Virtual Threads)|load-test-spring-boot-3:latest|-Dspring.threads.virtual.enabled=true")
fi

if [ "$profile" == "all" ] || [ "$profile" == "tuning" ]; then
  configs+=("Spring Boot 3.5 (Virtual + G1GC)|load-test-spring-boot-3:latest|-XX:+UseG1GC -Dspring.threads.virtual.enabled=true")
  configs+=("Spring Boot 3.5 (Virtual + Compact)|load-test-spring-boot-3:latest|-XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true")
  configs+=("Spring Boot 3.5 (Virtual + G1GC + Compact)|load-test-spring-boot-3:latest|-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true")
  configs+=("Spring Boot 3.5 (Virtual + CDS + G1GC + Compact)|load-test-spring-boot-3:cds|")
fi

if [ "$profile" == "all" ] || [ "$profile" == "native" ]; then
  configs+=("Spring Boot 3.5 (GraalVM Native - Platform Threads)|load-test-spring-boot-3:native|")
  configs+=("Spring Boot 3.5 (GraalVM Native - Virtual Threads)|load-test-spring-boot-3:native-virtual|")
fi

if [ "$profile" == "all" ] || [ "$profile" == "quick" ]; then
  configs+=("Spring Boot 4.1 (Platform Threads)|load-test-spring-boot-4:latest|")
fi

if [ "$profile" == "all" ] || [ "$profile" == "quick" ] || [ "$profile" == "tuning" ]; then
  configs+=("Spring Boot 4.1 (Virtual Threads)|load-test-spring-boot-4:latest|-Dspring.threads.virtual.enabled=true")
fi

if [ "$profile" == "all" ] || [ "$profile" == "tuning" ]; then
  configs+=("Spring Boot 4.1 (Virtual + G1GC)|load-test-spring-boot-4:latest|-XX:+UseG1GC -Dspring.threads.virtual.enabled=true")
  configs+=("Spring Boot 4.1 (Virtual + Compact)|load-test-spring-boot-4:latest|-XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true")
  configs+=("Spring Boot 4.1 (Virtual + G1GC + Compact)|load-test-spring-boot-4:latest|-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders -Dspring.threads.virtual.enabled=true")
  configs+=("Spring Boot 4.1 (Virtual + AOT + CDS + G1GC + Compact)|load-test-spring-boot-4:aot|")
fi

if [ "$profile" == "all" ] || [ "$profile" == "native" ]; then
  configs+=("Spring Boot 4.1 (GraalVM Native - Platform Threads)|load-test-spring-boot-4:native|")
  configs+=("Spring Boot 4.1 (GraalVM Native - Virtual Threads)|load-test-spring-boot-4:native-virtual|")
fi

configs+=("Go 1.27 (Echo v5)|load-test-go-echo:latest|")

wait_for_server() {
  local max_attempts=60
  local attempt=0
  echo -n "Waiting for container on port 8080..."
  while ! curl -s -o /dev/null "http://localhost:8080/benchmark/io-bound?value1=1&value2=1"; do
    sleep 0.5
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo " FAILED (timeout)"
      return 1
    fi
    echo -n "."
  done
  echo " READY!"
}

extract_startup_time() {
  local container_id=$1
  local logs
  logs=$(docker logs "$container_id" 2>&1)
  local startup="N/A"

  # Check Go log: "timeTaken":"X.XXXms"
  local go_time
  go_time=$(echo "$logs" | grep -o '"timeTaken":"[^"]*"' | head -1 | cut -d: -f2 | tr -d '"')
  if [ -n "$go_time" ]; then
    val=$(echo "$go_time" | sed 's/ms//')
    startup=$(awk -v v="$val" 'BEGIN {printf "%.1f ms", v}')
  fi

  if [ "$startup" == "N/A" ]; then
    # Check Spring Boot log: Started ... in X.XXX seconds
    local sb_sec
    sb_sec=$(echo "$logs" | grep -o 'Started [^ ]* in [0-9.]* seconds' | head -1 | awk '{print $(NF-1)}')
    if [ -n "$sb_sec" ]; then
      startup=$(awk -v s="$sb_sec" 'BEGIN {printf "%.1f ms", s * 1000}')
    fi
  fi

  echo "$startup"
}

# Results arrays
declare -a res_names=()
declare -a res_startups=()
declare -a res_min_rams=()
declare -a res_avg_rams=()
declare -a res_max_rams=()
declare -a res_sparklines=()
declare -a res_rpss=()
declare -a res_p95s=()
declare -a res_errors=()

echo ""
echo "[2/3] Executing Benchmark Matrix..."

for item in "${configs[@]}"; do
  IFS='|' read -r cfg_name cfg_image cfg_java_opts <<<"$item"

  echo ""
  echo ">>> [BENCHMARK] $cfg_name"
  echo "    Image: $cfg_image | JAVA_OPTS: ${cfg_java_opts:-[default]}"

  container_name="benchmark-runner"
  docker rm -f "$container_name" 2>/dev/null || true
  lsof -ti :8080 | xargs kill -9 2>/dev/null || true
  sleep 0.5

  # Start container with CPU & Memory constraints
  if [ -n "$cfg_java_opts" ]; then
    docker run -d --name "$container_name" --cpus="$cpus" --memory="$memory" -p 8080:8080 -e JAVA_OPTS="$cfg_java_opts" "$cfg_image" >/dev/null
  else
    docker run -d --name "$container_name" --cpus="$cpus" --memory="$memory" -p 8080:8080 "$cfg_image" >/dev/null
  fi

  wait_for_server
  startup_time=$(extract_startup_time "$container_name")

  summary_file=$(mktemp /tmp/bm_summary.XXXXXX)
  cd "$ROOT_DIR"
  "$SCRIPT_DIR/run_load_test.sh" -d "$container_name" -s "$k6_script" -c "$vus" -t "$duration" -o "$summary_file"

  # Source parsed metrics
  source "$summary_file"
  rm -f "$summary_file"

  docker stop "$container_name" >/dev/null
  docker rm "$container_name" >/dev/null

  res_names+=("$cfg_name")
  res_startups+=("$startup_time")
  res_min_rams+=("${min_ram:-0} MB")
  res_avg_rams+=("${avg_ram:-0} MB")
  res_max_rams+=("${max_ram:-0} MB")
  res_sparklines+=("[$sparkline]")
  res_rpss+=("${rps:-0}/s")
  res_p95s+=("${p95:-0} ms")
  res_errors+=("${errors:-0%}")

  sleep 2
done

echo ""
echo "[3/3] Generating Summary Report..."
echo ""
echo "======================================================================================================================"
echo "                                          BENCHMARK SUITE COMPARISON REPORT                                           "
echo "======================================================================================================================"
echo "Workload : $vus VUs | Duration: ${duration}s | Test: $test_type ($k6_script)"
echo "Limits   : CPU: $cpus cores | RAM: $memory"
echo "----------------------------------------------------------------------------------------------------------------------"
printf "| %-55s | %10s | %8s | %8s | %8s | %9s | %11s | %6s |\n" \
  "Configuration" "Startup" "Min RAM" "Avg RAM" "Max RAM" "RPS" "P95 Latency" "Errors"
echo "|:--------------------------------------------------------|-----------:|---------:|---------:|---------:|----------:|------------:|-------:|"

for ((i = 0; i < ${#res_names[@]}; i++)); do
  printf "| %-55s | %10s | %8s | %8s | %8s | %9s | %11s | %6s |\n" \
    "${res_names[i]}" "${res_startups[i]}" "${res_min_rams[i]}" "${res_avg_rams[i]}" "${res_max_rams[i]}" "${res_rpss[i]}" "${res_p95s[i]}" "${res_errors[i]}"
done
echo "======================================================================================================================"
