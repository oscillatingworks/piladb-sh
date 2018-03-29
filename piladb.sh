#!/bin/sh

### HELPERS

_log () {
  echo -e "$@" >&2
}

_exit_or_return () {
  [ "$PS1" ] && return $1 || exit $1;
}

_err_exit () {
  _log "error: $1"
  _exit_or_return 1
}

_require () {
  which $1 > /dev/null || _err_exit "piladb requires '$1'"
}

_require_host () {
  if [ -z "$PILADB_HOST" ]; then
    _log "env: please set PILADB_HOST, e.g. export PILADB_HOST=127.0.0.1:1205, or start a local server with piladb_start"
    _exit_or_return 1
  fi
}

### HTTP HELPERS

_piladb_get () {
  _require http
  _require_host || return 1

  http "$PILADB_HOST/$1?$2"
}

_piladb_put () {
  _require http
  _require_host || return 1

  http PUT "$PILADB_HOST/$1"
}

_piladb_post () {
  _require http
  _require_host || return 1

  http POST "$PILADB_HOST/$1" "element:=${@:2}"
}

_piladb_post_no_payload () {
  _require http
  _require_host || return 1

  http POST "$PILADB_HOST/$1"
}

_piladb_delete () {
  _require http
  _require_host || return 1

  http DELETE "$PILADB_HOST/$1"
}

### PILADB FUNCTIONS

piladb_help () {
  _log 'usage: piladb_*

  # if you want to use piladb in a remote host,
  # you can set PILADB_HOST for that purpose.
  # e.g. export PILADB_HOST=my.piladb.server:8080
  # default value is 127.0.0.1:1205

  # download pilad in $HOME/bin and add it to PATH
  # version: default is 0.1.5
  # os: linux, darwin. default is linux.
  piladb_download [version] [os]

  # start local pilad
  # if port is not set, it will default to 1205
  # if log_file is not set, it will default to pilad.log
  piladb_start [$port:1205] [$log_file:pilad.log]

  # stop local pilad
  # if pid is not set, it will stop a pilad process
  # running on port 1205
  piladb_stop [$pid]

  # ping piladb
  piladb_ping

  # show status of piladb
  piladb_status

  # show config of piladb
  piladb_config

  # show config value
  piladb_config_get $config_value

  # set config value
  piladb_config_set $config_value $config_key

  # show databases
  piladb_databases

  # create database
  piladb_create_database $database_name

  # show database
  piladb_database $database_name

  # delete database
  piladb_delete_database $database_name

  # show stacks in database
  piladb_stack $database_name

  # create stack in database
  piladb_create_stack $database_name $stack_name

  # show stack in database
  piladb_create_stack $database_name $stack_name

  # delete stack in database
  piladb_delete_stack $database_name $stack_name

  # PUSH element
  piladb_PUSH $database_name $stack_name $element

  # BASE element
  piladb_BASE $database_name $stack_name $element

  # POP element
  piladb_POP $database_name $stack_name

  # PEEK element
  piladb_PEEK $database_name $stack_name

  # FLUSH stack
  piladb_FLUSH $database_name $stack_name

  # ROTATE stack
  piladb_ROTATE $database_name $stack_name

  # BLOCK stack
  piladb_BLOCK $database_name $stack_name

  # UNBLOCK stack
  piladb_UNBLOCK $database_name $stack_name

  # SIZE of stack
  piladb_SIZE $database_name $stack_name

  # Stack is EMPTY
  piladb_SIZE $database_name $stack_name

  # Stack is FULL
  piladb_FULL $database_name $stack_name

requirements:

  httpie: https://github.com/jkbrzt/httpie#installation

thank you!

  https://www.piladb.org
  https://github.com/oscillatingworks/piladb-sh
  https://twitter.com/oscillatingw'
}

piladb_download () {
  local VERSION="${1:-"0.1.5"}"
  local OS="${2:-"linux"}"

  _log "Downloading piladb${VERSION}.${OS}-amd64.tar.gz..."
  local DOWNLOAD_URL="https://github.com/fern4lvarez/piladb/releases/download/v${VERSION}/piladb${VERSION}.${OS}-amd64.tar.gz"
  wget -q "$DOWNLOAD_URL"

  if [ $? -ne 0 ]; then
    _err_exit "Version ${VERSION} does not exist or error downloading it. Exiting..."
  else
    _log "Extracting in ${PWD}..."
    tar -zxvf "piladb${VERSION}.${OS}-amd64.tar.gz"

    _log "Moving binary to ${HOME}/bin..."
    mkdir -p "${HOME}/bin"
    mv pilad "${HOME}/bin"
    export PATH="${PATH}:${HOME}/bin"

    _log "Cleanup..."
    rm "piladb${VERSION}.${OS}-amd64.tar.gz"

    _log "Done! $(pilad -v)"
  fi
}

piladb_start () {
  _require pilad || return 1

  local PORT="${1:-"1205"}"
  local LOG_FILE="${2:-"pilad.log"}"

  _log "starting pilad in port ${PORT} logging to ${LOG_FILE}"
  pilad -port $PORT &> $LOG_FILE &

  # we override PILADB_HOST, as we are using a piladb local server
  export PILADB_HOST="127.0.0.1:$PORT"
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

piladb_ping () {
  _piladb_get "_ping"
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

piladb_databases () {
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

piladb_database () {
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

piladb_stacks () {
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

piladb_stack () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"
  local OP="$3"

  if [ -z "$DATABASE_NAME" ]; then
    _log "stacks: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "stacks: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_get "databases/${DATABASE_NAME}/stacks/${STACK_NAME}" "${OP}"
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
  local ELEMENT="${@:3}"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  elif [ -z "$ELEMENT" ]; then
    _log "push: please provide an element"
    _exit_or_return 1
  else
    _piladb_post "databases/${DATABASE_NAME}/stacks/${STACK_NAME}" "$ELEMENT"
  fi
}

piladb_BASE () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"
  local ELEMENT="${@:3}"

  piladb_PUSH "$DATABASE_NAME" "$STACK_NAME?base" "$ELEMENT"
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

  piladb_stack "$DATABASE_NAME" "$STACK_NAME" "peek"
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

piladb_ROTATE () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "push: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "push: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_post_no_payload "databases/${DATABASE_NAME}/stacks/${STACK_NAME}?rotate"
  fi
}

piladb_BLOCK () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "stacks: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "stacks: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_put "databases/${DATABASE_NAME}/stacks/$STACK_NAME?block"
  fi
}

piladb_UNBLOCK () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  if [ -z "$DATABASE_NAME" ]; then
    _log "stacks: please provide a database name"
    _exit_or_return 1
  elif [ -z "$STACK_NAME" ]; then
    _log "stacks: please provide an stack name"
    _exit_or_return 1
  else
    _piladb_put "databases/${DATABASE_NAME}/stacks/$STACK_NAME?unblock"
  fi
}

piladb_SIZE () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  piladb_stack "$DATABASE_NAME" "$STACK_NAME" "size"
}

piladb_EMPTY () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  piladb_stack "$DATABASE_NAME" "$STACK_NAME" "empty"
}

piladb_FULL () {
  local DATABASE_NAME="$1"
  local STACK_NAME="$2"

  piladb_stack "$DATABASE_NAME" "$STACK_NAME" "full"
}

### ALIASES

alias PUSH='piladb_PUSH'
alias BASE='piladb_BASE'
alias POP='piladb_POP'
alias PEEK='piladb_PEEK'
alias FLUSH='piladb_FLUSH'
alias ROTATE='piladb_ROTATE'
alias BLOCK='piladb_BLOCK'
alias UNBLOCK='piladb_UNBLOCK'
alias SIZE='piladb_SIZE'
alias EMPTY='piladb_EMPTY'
alias FULL='piladb_FULL'
