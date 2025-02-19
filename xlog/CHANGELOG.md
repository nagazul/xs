## [4.0.3] - 2025-02-19
- **Enhancements**: Updated to production-ready version; improved error handling
  with `exit_with_error`; tightened security (log permissions to 600, expanded
  env filtering); optimized performance (`stat` over `du`, `$SECONDS` for
  timing); split `log_event` into `_log_json` and `_log_plain`; enhanced
  portability; added CPU/memory metrics in DEBUG mode only; streamlined
  `execute_command`.
- **Fixes**: Fixed log rotation permissions; ensured session ID is set early;
  removed redundant `padded_level`.
- **Security**: Restricted log file access; improved env variable filtering.
- **Compatibility**: Added fallbacks for optional tools (`logger`, `timeout`).

## [4.0.2] - 2025-02-18
- **Improved**: Added `XID` session ID for downstream tracking.

## [4.0.1] - 2025-02-18
- **Changed**: Renamed from `wrap.sh` to `xlog`; changed default log dir to
  `~/.log` from `/var/log`.
- **Improved**: Polished script for production use.

## [4.0.0] - 2025-02-18
- **Notes**: Major version bump for new `xlog` identity and production
  readiness.

## [3.1.2] - 2025-02-18
- **Changed**: Condensed DEBUG timing output to a single line (e.g.,
  "real=0.01s, user=0.00s, sys=0.00s").

## [3.1.1] - 2025-02-18
- **Changed**: Padded log levels to 5 chars; moved `chmod` to `setup_logging`.
- **Improved**: Added dependency checks for `logger` and `timeout`; enhanced
  JSON escaping.
- **Fixed**: Graceful degradation for syslog and timeout features.

## [3.1.0] - 2025-02-17
- **Added**: `--silent`, `--json-log`, `--syslog`, `--timeout`, CPU tracking,
  `-v/--version`, SIGHUP handler.
- **Changed**: Filtered sensitive env vars; made config readonly.
- **Improved**: Structured JSON logging; refined signal handlers.

## [3.0.0] - 2025-01-15
- **Added**: Configurable log rotation; log level array; timezone in
  timestamps.
- **Changed**: Switched to numbered log backups; updated log format.
- **Improved**: Modular `setup_logging`; better SSH_CLIENT handling.
- **Removed**: Legacy log level function.

## [2.0.1] - 2024-12-20
- **Fixed**: Handled `SSH_CLIENT` unbound error; fixed rotation permissions.
- **Improved**: Added `ps` fallback for memory metrics.

## [2.0.0] - 2024-12-10
- **Added**: Signal handlers (SIGUSR1, SIGUSR2, SIGINT, SIGTERM); DEBUG
  timing; memory tracking.
- **Changed**: Reworked execution for debug capture; added `gzip` compression.
- **Improved**: Added duration metric.

## [1.1.0] - 2024-11-15
- **Added**: Option parsing (`--log-level`, `--log-file`, etc.); env var
  support; basic log rotation.
- **Changed**: Configurable log paths; improved log format.

## [1.0.0] - 2024-10-30
- **Added**: Log levels; basic logging to `/var/log/command_wrapper.log`; exit
  code logging.
- **Notes**: Initial stable release.

## [0.0.2] - 2024-10-15
- **Fixed**: Log path errors; preserved exit codes.
- **Improved**: Added basic help.

## [0.0.1] - 2024-10-01
- **Added**: Initial command execution and logging.
- **Notes**: Proof of concept.
