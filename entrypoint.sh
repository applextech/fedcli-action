#!/bin/sh
set -eu

fail() {
  printf '%s\n' "FedCLI Action error: $*" >&2
  exit 2
}

sql=${INPUT_SQL:-}
script=${INPUT_SCRIPT:-}
connection_url=${INPUT_CONNECTION_URL:-}
workspace=${GITHUB_WORKSPACE:-/github/workspace}
working_directory_input=${INPUT_WORKING_DIRECTORY:-.}

if [ -n "$sql" ] && [ -n "$script" ]; then
  fail "inputs 'sql' and 'script' are mutually exclusive."
fi

if [ -z "$sql" ] && [ -z "$script" ]; then
  fail "provide exactly one of 'sql' or 'script'."
fi

workspace=$(realpath -m "$workspace")
working_directory=$(realpath -m "$workspace/$working_directory_input")
case "$working_directory" in
  "$workspace"|"$workspace"/*) ;;
  *) fail "working-directory must remain inside GITHUB_WORKSPACE." ;;
esac

if [ -n "$script" ]; then
  script_path=$(realpath -m "$working_directory/$script")
  case "$script_path" in
    "$working_directory"/*) ;;
    *) fail "script must remain inside working-directory." ;;
  esac
  [ -f "$script_path" ] || fail "script does not exist: $script"
fi

input_file=$(mktemp /tmp/fedcli-action-XXXXXX.sql)
chmod 0600 "$input_file"
trap 'rm -f "$input_file"' EXIT HUP INT TERM

printf '%s\n' 'WHENEVER SQLERROR EXIT FAILURE;' > "$input_file"

if [ -n "$connection_url" ]; then
  escaped_connection_url=$(printf '%s' "$connection_url" | sed "s/'/''/g")
  printf "CONNECT '%s';\n" "$escaped_connection_url" >> "$input_file"
fi

if [ -n "$sql" ]; then
  printf '%s\n' "$sql" >> "$input_file"
else
  cat "$script_path" >> "$input_file"
fi

exec java -Duser.home=/tmp/fedcli-home -jar /opt/fedcli/fedcli.jar -c "@$input_file"
