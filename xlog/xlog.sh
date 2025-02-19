#!/bin/bash
# xlog - Execution Log - Logs command execution with detailed metrics

set -u

# Configuration (overridable via environment variables)
LOG_DIR="${XLOG_LOG_DIR:-${HOME}/.log}"
LOG_FILE="${XLOG_LOG_FILE:-${LOG_DIR}/xlog.log}"
MAX_LOG_SIZE="${XLOG_MAX_LOG_SIZE:-10485760}"  # 10MB
ROTATE_COUNT="${XLOG_ROTATE_COUNT:-5}"
ROTATE_LOGS="${XLOG_ROTATE_LOGS:-true}"
INCLUDE_ENV="${XLOG_INCLUDE_ENV:-false}"
LOG_LEVEL="${XLOG_LOG_LEVEL:-INFO}"
SILENT_MODE="${XLOG_SILENT:-false}"
SYSLOG_ENABLE="${XLOG_SYSLOG:-false}"
SYSLOG_FACILITY="${XLOG_SYSLOG_FACILITY:-local0}"
TIMEOUT="${XLOG_TIMEOUT:-0}"
JSON_LOG="${XLOG_JSON_LOG:-false}"
SESSION_ID="${XID:-}"

# Validate core dependencies
for cmd in date hostname whoami bc ps gzip; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: Required command '$cmd' not found" >&2; exit 1; }
done

# Log levels
declare -A LOG_LEVELS=( [DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 )

# Centralized error exit
exit_with_error() {
    local msg="$1" code="${2:-1}"
    log_event "ERROR" "$msg" 2>/dev/null || echo "ERROR: $msg" >> "${LOG_FILE:-/tmp/xlog.log}"
    echo "Error: $msg" >&2
    exit "$code"
}

# Setup logging directory and file
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")" || exit_with_error "Cannot create log directory $(dirname "$LOG_FILE")"
    touch "$LOG_FILE" || exit_with_error "Cannot write to log file $LOG_FILE"
    chmod 600 "$LOG_FILE" || log_event "WARN" "Could not set restrictive permissions on $LOG_FILE"
}

# Rotate logs if needed
rotate_logs() {
    [[ "$ROTATE_LOGS" != "true" || ! -f "$LOG_FILE" ]] && return
    #echo "DEBUG: LOG_FILE=$LOG_FILE" >&2  # Debug output
    local file_size=0  # Default to 0 if all methods fail
    if command -v stat >/dev/null 2>&1; then
        file_size=$(stat -c %s "$LOG_FILE" 2>/dev/null || stat -f %z "$LOG_FILE" 2>/dev/null) || \
            file_size=$(du -b "$LOG_FILE" 2>/dev/null | cut -f1) || \
            { echo "DEBUG: Failed to get file size for $LOG_FILE, assuming 0" >&2; file_size=0; }
    else
        file_size=$(du -b "$LOG_FILE" 2>/dev/null | cut -f1) || \
            { echo "DEBUG: Failed to get file size for $LOG_FILE, assuming 0" >&2; file_size=0; }
    fi
    if [[ -n "$file_size" && "$file_size" -gt "$MAX_LOG_SIZE" ]]; then
        #echo "DEBUG: Rotating logs, size=$file_size, max=$MAX_LOG_SIZE" >&2
        [[ -f "${LOG_FILE}.${ROTATE_COUNT}.gz" ]] && rm -f "${LOG_FILE}.${ROTATE_COUNT}.gz"
        for ((i=ROTATE_COUNT-1; i>=1; i--)); do
            [[ -f "${LOG_FILE}.${i}.gz" ]] && mv "${LOG_FILE}.${i}.gz" "${LOG_FILE}.$((i+1)).gz"
        done
        mv "$LOG_FILE" "${LOG_FILE}.1"
        gzip "${LOG_FILE}.1" &>/dev/null &
        touch "$LOG_FILE" && chmod 600 "$LOG_FILE"
    fi
}

# Log event in JSON format
_log_json() {
    local timestamp="$1" level="$2" hostname="$3" pid="$4" user="$5" message="$6"
    local escaped_message=$(echo "$message" | tr '\n' ' ' | sed 's/"/\\"/g; s/\\/\\\\/g')
    printf '{"timestamp":"%s","level":"%s","hostname":"%s","xid":"%s","pid":%d,"user":"%s","message":"%s"}\n' \
        "$timestamp" "$level" "$hostname" "$SESSION_ID" "$pid" "$user" "$escaped_message" >> "$LOG_FILE"
}

# Log event in plain format
_log_plain() {
    local timestamp="$1" level="$2" hostname="$3" pid="$4" user="$5" message="$6"
    printf '%s [%5s] [%s] [XID:%s PID:%d] [%s] - %s\n' \
        "$timestamp" "$level" "$hostname" "$SESSION_ID" "$pid" "$user" "$message" >> "$LOG_FILE"
}

# Main logging function
log_event() {
    local level="$1" message="$2"
    [[ ${LOG_LEVELS[${level^^}]:-1} -lt ${LOG_LEVELS[${LOG_LEVEL^^}]:-1} ]] && return

    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')
    local hostname=${HOSTNAME:-$(hostname -s 2>/dev/null || echo "unknown")}
    local pid=$$ user="${USER:-$(whoami 2>/dev/null || echo 'unknown')}"

    if [[ "$JSON_LOG" == "true" ]]; then
        _log_json "$timestamp" "$level" "$hostname" "$pid" "$user" "$message"
    else
        _log_plain "$timestamp" "$level" "$hostname" "$pid" "$user" "$message"
    fi
    [[ "$SYSLOG_ENABLE" == "true" && $(command -v logger >/dev/null 2>&1) ]] && \
        logger -p "${SYSLOG_FACILITY}.${level,,}" -t "xlog[$SESSION_ID:$$]" "$message" 2>/dev/null
}

# Handle command execution with timeout
handle_timeout() {
    export XID="$SESSION_ID"
    if [[ "$TIMEOUT" -gt 0 ]] && command -v timeout >/dev/null 2>&1; then
        timeout "$TIMEOUT" "$@"
        local exit_code=$?
        [[ $exit_code -eq 124 ]] && { log_event "ERROR" "Command timed out after ${TIMEOUT}s: $*"; return 124; }
        return $exit_code
    else
        "$@"
        return $?
    fi
}

# Execute command and capture metrics
execute_command() {
    local cmd=("$@") output timing exit_code duration
    local start_time=$SECONDS start_memory end_memory memory_diff start_cpu end_cpu cpu_diff

    [[ "${LOG_LEVEL^^}" == "DEBUG" ]] && {
        start_memory=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
        start_cpu=$(ps -o %cpu= -p $$ 2>/dev/null || echo 0)
    }

    if [[ "$SILENT_MODE" == "true" ]]; then
        output=$( { time -p handle_timeout "${cmd[@]}" >/dev/null 2>&1; } 2>&1 )
    else
        exec 5>&1 6>&2
        output=$( { time -p handle_timeout "${cmd[@]}" 1>&5 2>&6; } 2>&1 )
        exec 5>&- 6>&-
    fi
    exit_code=$?

    duration=$(printf "%.3f" "$((SECONDS - start_time))")
    [[ "${LOG_LEVEL^^}" == "DEBUG" ]] && {
        end_memory=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
        end_cpu=$(ps -o %cpu= -p $$ 2>/dev/null || echo 0)
        memory_diff=$((end_memory - start_memory))
        cpu_diff=$(echo "$end_cpu - $start_cpu" | bc 2>/dev/null || echo 0)
        metrics="exit: $exit_code, time: ${duration}s, memory: ${memory_diff}KB, cpu: ${cpu_diff}%"
        [[ -n "$output" ]] && _log_timing "$output"
    } || metrics="exit: $exit_code, time: ${duration}s"

    return $exit_code
}

# Log detailed timing for DEBUG mode
_log_timing() {
    local output="$1" output_size=${#output}
    if [[ $output_size -lt 1024 ]]; then
        timing=$(echo "$output" | awk '/real/ {real=$2} /user/ {user=$2} /sys/ {sys=$2} END {printf "real=%.2fs, user=%.2fs, sys=%.2fs", real, user, sys}')
        log_event "DEBUG" "Timing: $timing"
    else
        log_event "DEBUG" "Timing output too large (${output_size} bytes)"
    fi
}

# Version and help
show_version() {
    echo "xlog v4.0.3 - Execution Log"
    exit 0
}

show_help() {
    cat << EOF
xlog v4.0.3 - Execution Log

Logs command execution with detailed metrics.

Usage: xlog [options] command [args...]

Options:
  --log-level=LEVEL      Set logging level (DEBUG, INFO, WARN, ERROR)
  --log-file=FILE        Set log file path (default: ~/.log/xlog.log)
  --no-rotate            Disable log rotation
  --rotate-count=NUM     Number of rotated logs to keep (default: 5)
  --include-env          Log environment variables (sensitive vars filtered)
  --silent               Suppress command output
  --json-log             Use JSON log format
  --syslog               Enable syslog logging (requires logger)
  --syslog-facility=FAC  Set syslog facility (default: local0)
  --timeout=SECONDS      Set command timeout (0=disabled, requires timeout)
  --xid=ID               Set custom session ID for tracking related processes
  -v, --version          Show version
  -h, --help             Show this help

Environment Variables:
  XLOG_LOG_DIR        Log directory (default: ~/.log)
  XLOG_LOG_FILE       Log file path
  XLOG_MAX_LOG_SIZE   Max log size in bytes (default: 10MB)
  XLOG_ROTATE_LOGS    Enable log rotation (true/false)
  XLOG_ROTATE_COUNT   Number of rotated logs
  XLOG_INCLUDE_ENV    Log environment (true/false)
  XLOG_LOG_LEVEL      Logging level
  XLOG_SILENT         Suppress output (true/false)
  XLOG_SYSLOG         Enable syslog (true/false)
  XLOG_SYSLOG_FACILITY Syslog facility
  XLOG_TIMEOUT        Command timeout in seconds
  XLOG_JSON_LOG       Use JSON logs (true/false)
  XID                 Universal session ID

Examples:
  xlog ls -la
  xlog --log-level=DEBUG --include-env find / -name "*.conf"
  xlog --json-log --timeout=300 my_script.sh
EOF
    exit 0
}

# Trap signals
trap 'log_event "INFO" "Received SIGUSR1: $*" ' SIGUSR1
trap 'log_event "INFO" "Received SIGUSR2: $*" ' SIGUSR2
trap 'log_event "WARN" "Received SIGINT: $*"; exit 130' SIGINT
trap 'log_event "WARN" "Received SIGTERM: $*"; exit 143' SIGTERM
trap 'log_event "ERROR" "Received SIGHUP: $*"; exit 129' SIGHUP

# Parse options
while [[ "${1:-}" == -* ]]; do
    case "$1" in
        --log-level=*) LOG_LEVEL="${1#*=}" ;;
        --log-file=*) LOG_FILE="${1#*=}" ;;
        --no-rotate) ROTATE_LOGS="false" ;;
        --rotate-count=*) ROTATE_COUNT="${1#*=}" ;;
        --include-env) INCLUDE_ENV="true" ;;
        --silent) SILENT_MODE="true" ;;
        --json-log) JSON_LOG="true" ;;
        --syslog) SYSLOG_ENABLE="true" ;;
        --syslog-facility=*) SYSLOG_FACILITY="${1#*=}" ;;
        --timeout=*) TIMEOUT="${1#*=}" ;;
        --xid=*) SESSION_ID="${1#*=}" ;;
        --help|-h) show_help ;;
        --version|-v) show_version ;;
        --) shift; break ;;
        -*) exit_with_error "Unknown option: $1. Try 'xlog --help' for usage" ;;
    esac
    shift
done

# Validate configuration
[[ $# -eq 0 ]] && exit_with_error "No command specified. Try 'xlog --help' for usage"
[[ ! "${LOG_LEVELS[${LOG_LEVEL^^}]+x}" ]] && exit_with_error "Invalid log level: $LOG_LEVEL"
[[ ! "$ROTATE_COUNT" =~ ^[0-9]+$ ]] && exit_with_error "Rotate count must be a number"
[[ ! "$TIMEOUT" =~ ^[0-9]+$ ]] && exit_with_error "Timeout must be a number"
[[ "$SYSLOG_ENABLE" == "true" && ! $(command -v logger >/dev/null 2>&1) ]] && { log_event "WARN" "'logger' not found, syslog disabled"; SYSLOG_ENABLE="false"; }
[[ "$TIMEOUT" -gt 0 && ! $(command -v timeout >/dev/null 2>&1) ]] && { log_event "WARN" "'timeout' not found, ignoring --timeout=$TIMEOUT"; TIMEOUT=0; }

# Set default SESSION_ID if not provided
if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(echo "$(date +%s%N)$$" | md5sum | head -c 8)
fi
export XID="$SESSION_ID"

# Lock configuration
readonly LOG_DIR LOG_FILE MAX_LOG_SIZE ROTATE_COUNT ROTATE_LOGS INCLUDE_ENV LOG_LEVEL SILENT_MODE SYSLOG_ENABLE SYSLOG_FACILITY TIMEOUT JSON_LOG SESSION_ID
readonly -A LOG_LEVELS

# Initialize logging
setup_logging
rotate_logs

# Log start
client_ip="local"
[[ -n "${SSH_CLIENT:-}" ]] && client_ip="${SSH_CLIENT%% *}"
current_dir=$(pwd -P 2>/dev/null || pwd)
log_event "INFO" "Starting command: $* (dir: $current_dir) (client: $client_ip)"
[[ "$INCLUDE_ENV" == "true" ]] && log_event "DEBUG" "Environment: $(env | sort | grep -v -E '^(PASSWORD|SECRET|TOKEN|KEY|CREDENTIAL|PASS|API)' | tr '\n' ' ')"

# Execute and log results
execute_command "$@"
exit_code=$?
status=$([ $exit_code -eq 0 ] && echo "SUCCESS" || echo "FAILED")
[[ $exit_code -eq 124 && "$TIMEOUT" -gt 0 ]] && log_event "ERROR" "TIMEOUT: Command exceeded ${TIMEOUT}s: $* ($metrics)" || log_event "INFO" "$status: Command: $* ($metrics)"

exit $exit_code
