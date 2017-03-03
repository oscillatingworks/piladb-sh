#!/bin/sh

### HELPERS

_log () {
  echo -e "$@" >&2
}

_exit_or_return () {
  [ "$PS1" ] && return || exit $1;
}

_err_exit () {
  _log "error: $1"
  _exit_or_return 1
}

_require () {
  which $1 > /dev/null || _err_exit "$0 requires '$1'"
}

_require_host () {
  if [ -z "$PILADB_HOST" ]; then
    _log "env: please set PILADB_HOST, e.g. export PILADB_HOST=127.0.0.1:1205"
    _exit_or_return 1
  fi
}

### HTTP HELPERS

_piladb_get () {
  _require http
  _require_host

  http $PILADB_HOST/$1
}

_piladb_put () {
  _require http
  _require_host

  http PUT $PILADB_HOST/$1
}

_piladb_post () {
  _require http
  _require_host

  http POST $PILADB_HOST/$1 element=$2
}

_piladb_delete () {
  _require http
  _require_host

  http DELETE $PILADB_HOST/$1
}

### PILADB FUNCTIONS

piladb_help () {
  _log 'usage: piladb_*

  # start local pilad
  # if port is not set, it will default to 1205
  # if log_file is not set, it will default to pilad.log
  piladb_start [$port:1205] [$log_file:pilad.log]

  # stop local pilad
  # if pid is not set, it will stop a pilad process
  # running on port 1205
  piladb_start $pid

  # show status of piladb
  piladb_status

  # show config of piladb
  piladb_config

  # show config value
  piladb_config_get $config_value

  # set config value
  piladb_config_set $config_value $config_key

  # show databases
  piladb_show_databases

  # create database
  piladb_create_database $database_name

  # show database
  piladb_show_database $database_name

  # delete database
  piladb_delete_database $database_name

  # show stacks in database
  piladb_show_stack $database_name

  # create stack in database
  piladb_create_stack $database_name $stack_name

  # show stack in database
  piladb_create_stack $database_name $stack_name

  # delete stack in database
  piladb_delete_stack $database_name $stack_name

  # PUSH element
  piladb_PUSH $database_name $stack_name $element

  # POP element
  piladb_POP $database_name $stack_name

  # PEEK element
  piladb_PEEK $database_name $stack_name

  # SIZE of stack
  piladb_SIZE $database_name $stack_name

  # FLUSH stack
  piladb_FLUSH $database_name $stack_name

requirements:

  httpie: https://github.com/jkbrzt/httpie#installation
  PILADB_HOST set, e.g. export PILADB_HOST=127.0.0.1:1205

thank you!

  https://www.piladb.org
  https://github.com/oscillatingworks/piladb-sh
  https://twitter.com/oscillatingw'
}

piladb_start () {
  _require pilad

  local PORT="${1:-"1205"}"
  local LOG_FILE="${2:-"pilad.log"}"

  _log "starting pilad in port ${PORT} logging to ${LOG_FILE}"
  pilad -port $PORT &> $LOG_FILE &
}

piladb_stop () {
  local PILADB_PID="${1:-"$(ps aux | grep "pilad -port 1205" | grep -v grep | awk '{print $2}')"}"

  if [ -z "$PILADB_PID" ]; then
    _log "no pilad running"
  else
    _log "killing pilad running in ${PILADB_PID}"
    kill "${PILADB_PID}"
  fi
}

piladb_status () {
  _piladb_get "_status"
}

piladb_config () {
  _piladb_get "_config"
}

piladb_config_get () {
  local CONFIG_KEY="$1"

  if [ -z "$CONFIG_KEY" ]; then
    _log "config: please provide a config key"
    _exit_or_return 1
  else
    _piladb_get "_config/${CONFIG_KEY}"
  fi
}

piladb_config_set () {
  local CONFIG_KEY="$1"
  local CONFIG_VALUE="$2"

  if [ -z "$CONFIG_KEY" ]; then
    _log "config: please provide a config key"
    _exit_or_return 1
  elif [ -z "${CONFIG_VALUE}" ]; then
    _log "config: please provide a config value"
    _exit_or_return 1
  else
    _piladb_post "_config/${CONFIG_KEY}" "$CONFIG_VALUE"
  fi
}

piladb_show_databases () {
  _piladb_get "databases"
}

piladb_create_database () {
  local DATABASE_NAME="$1"

  if [ -z "$DATABASE_NAME" ]; then
    _log "databases: please provide a database name"
    _exit_or_return 1
  else
    _piladb_put "databases?name=${DATABASE_NAME}"
  fi
}

piladb_show_database () {
  local DATABASE_NAME="$1"

  if [ -z "$DATABASE_NAME" ]; then
    _log "databases: please provide a database name"
    _exit_or_return 1
  else
    _piladb_get "databases/${DATABASE_NAME}"
  fi
}

piladb_delete_database () {
  local DATABASE_NAME="$1"

  if [ -z "$DATABASE_NAME" ]; then
    _log "databases: please provide a database name"
    _exit_or_return 1
  else
    _piladb_delete "databases/${DATABASE_NAME}"
  fi
}

piladb_show_stacks () {
  local DATABASE_NAME="$1"

  if [ -z "$DATABASE_NAME" ]; then
    _log "databases: please provide a database name"
    _exit_or_return 1
  else
    _piladb_get "databases/${DATABASE_NAME}/stacks"
  fi
}

piladb_create_stack () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "stacks: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "stacks: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_put "databases/${DATABASE_NAME}/stacks?name=${STACK_NAME}"
  fi
}

piladb_show_stack () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "stacks: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "stacks: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_get "databases/${DATABASE_NAME}/stacks/${STACK_NAME}"
  fi
}

piladb_delete_stack () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "stacks: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "stacks: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_delete "databases/${DATABASE_NAME}/stacks/${STACK_NAME}?full"
  fi
}

piladb_PUSH () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"
  local ELEMENT="$3"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  elif [ -z "${ELEMENT}" ]; then
    _log "push: please provide an element"
    _exit_or_return 1
  else
    _piladb_post "databases/${DATABASE_NAME}/stacks/${STACK_NAME}" $ELEMENT
  fi
}

piladb_POP () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_delete "databases/${DATABASE_NAME}/stacks/${STACK_NAME}"
  fi
}

piladb_PEEK () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_get "databases/${DATABASE_NAME}/stacks/${STACK_NAME}?peek"
  fi
}

piladb_SIZE () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_get "databases/${DATABASE_NAME}/stacks/${STACK_NAME}?size"
  fi
}

piladb_FLUSH () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_delete "databases/${DATABASE_NAME}/stacks/${STACK_NAME}?flush"
  fi
}
