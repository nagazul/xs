# xlog - Execution Log

xlog is a Bash script that logs command execution with detailed metrics like
exit status, execution time, memory usage, and CPU usage. It supports log
rotation, JSON output, syslog integration, and command timeouts.

## Installation

1. Make xlog.sh executable:
   ```
   chmod +x xlog.sh
   ```
2. Move/Rename to a directory in your PATH:
   ```
   sudo cp xlog.sh /usr/local/bin/xlog
   ```

## Requirements

- Required: bash, date, hostname, whoami, bc, ps, gzip
- Optional: timeout (for timeouts), logger (for syslog), md5sum (for session
  IDs)

## Usage

Run xlog followed by a command:
```
xlog [options] command [args...]
```

Examples:
```
xlog ls -la
xlog --log-level=DEBUG --include-env find / -name "*.conf"
xlog --json-log --timeout=300 my_script.sh
xlog --silent curl -o /dev/null https://example.com
```

## Options

```
--log-level=LEVEL     Set logging level (DEBUG, INFO, WARN, ERROR) [default:
                      INFO]
--log-file=FILE       Set log file path [default: ~/.log/xlog.log]
--no-rotate           Disable log rotation [default: enabled]
--rotate-count=NUM    Number of rotated logs to keep [default: 5]
--include-env         Log environment variables (sensitive data filtered)
--silent              Suppress command output
--json-log            Use JSON log format
--syslog              Enable syslog logging (requires logger)
--syslog-facility=FAC Set syslog facility [default: local0]
--timeout=SECONDS     Set command timeout (requires timeout) [default: 0]
--xid=ID              Set custom session ID
-v, --version         Show version
-h, --help            Show this help
```

## Environment Variables

```
XLOG_LOG_DIR         Log directory [default: ~/.log]
XLOG_LOG_FILE        Log file path [default: ~/.log/xlog.log]
XLOG_MAX_LOG_SIZE    Max log size in bytes [default: 10485760 (10MB)]
XLOG_ROTATE_LOGS     Enable log rotation (true/false) [default: true]
XLOG_ROTATE_COUNT    Number of rotated logs [default: 5]
XLOG_INCLUDE_ENV     Log environment (true/false) [default: false]
XLOG_LOG_LEVEL       Logging level [default: INFO]
XLOG_SILENT          Suppress output (true/false) [default: false]
XLOG_SYSLOG          Enable syslog (true/false) [default: false]
XLOG_SYSLOG_FACILITY Syslog facility [default: local0]
XLOG_TIMEOUT         Command timeout in seconds [default: 0]
XLOG_JSON_LOG        Use JSON logs (true/false) [default: false]
XID                  Universal session ID
```

## Log Output

- Plain text (default):
  ```
  2025-02-19T12:34:56+0000 [INFO ] [hostname] [XID:abcdef12 PID:1234] [user] -
  Starting command: ls -la
  ```
- JSON:
  ```
  {"timestamp":"2025-02-19T12:34:56+0000","level":"INFO""hostname":"hostname",
  "xid":"asjdh332","pid":1234,"user":"user","message":"Starting command: ls -la"}
  ```
