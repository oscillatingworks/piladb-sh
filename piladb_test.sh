#!/bin/sh

set -e

source piladb.sh
_require jq || exit 1


# download pilad from Github

piladb_download 0.2.0-alpha.20180407 linux


# start test pilad

piladb_start


# test status

ok=$(piladb_status | jq '.status')
if [ "$ok" != '"OK"' ]; then
   _log "ERROR: status is $ok, expected OK"
   piladb_stop
   exit 1
fi

pid=$(piladb_status | jq '.pid')


# test config

piladb_config

max_stack_size=$(piladb_config_get MAX_STACK_SIZE | jq '.element')
if [ "$max_stack_size" != -1 ]; then
   _log "ERROR: MAX_STACK_SIZE is $max_stack_size, expected -1"
   piladb_stop $pid
   exit 1
fi

piladb_config_set MAX_STACK_SIZE 10

max_stack_size=$(piladb_config_get MAX_STACK_SIZE | jq '.element')
if [ "$max_stack_size" != 10 ]; then
   _log "wrong MAX_STACK_SIZE is $max_stack_size, expected 10"
   piladb_stop $pid
   exit 1
fi


# test databases

number_of_databases=$(piladb_databases | jq '.number_of_databases')
if [ "$number_of_databases" -ne "0" ]; then
   _log "ERROR: no databases expected, got $number_of_databases"
   piladb_stop $pid
   exit 1
fi

piladb_create_database db1
piladb_create_database db2
piladb_create_database db3

number_of_databases=$(piladb_databases | jq '.number_of_databases')
if [ "$number_of_databases" -ne "3" ]; then
   _log "ERROR: number of databases is $number_of_databases, expected 3"
   piladb_stop $pid
   exit 1
fi

piladb_delete_database db2
number_of_databases=$(piladb_database db2 | jq '.number_of_databases')
if [ -n "$number_of_databases" ]; then
   _log "ERROR: database db2 exists"
   piladb_stop $pid
   exit 1
fi


# test stacks

piladb_create_stack db1 mystack1
piladb_create_stack db1 mystack2
piladb_create_stack db1 mystack3

number_of_stacks=$(piladb_database db1 | jq '.number_of_stacks')
if [ "$number_of_stacks" -ne "3" ]; then
   _log "ERROR: number of stacks is $number_of_stacks, expected 3"
   piladb_stop $pid
   exit 1
fi

piladb_stack db1 mystack1

piladb_PUSH db1 mystack1 false
piladb_PUSH db1 mystack1 '{"json":"example"}'
piladb_PUSH db1 mystack1 1
piladb_PUSH db1 mystack1 '"this is a string"'
piladb_BASE db1 mystack1 '[1,2,3,5,8,13]'

popped=$(piladb_POP db1 mystack1 | jq '.element')
if [ "$popped" != '"this is a string"' ]; then
   _log "ERROR: popped is $popped, expected \"this is a string\""
   piladb_stop $pid
   exit 1
fi

peek=$(piladb_PEEK db1 mystack1 | jq '.element')
if [ "$peek" != 1 ]; then
   _log "ERROR: peek is $peek, expected 1"
   piladb_stop $pid
   exit 1
fi

size=$(piladb_SIZE db1 mystack1)
if [ "$size" -ne 4 ]; then
   _log "ERROR: size is $size, expected 4"
   piladb_stop $pid
   exit 1
fi

piladb_FLUSH db1 mystack1

size=$(piladb_SIZE db1 mystack1)
if [ "$size" -ne "0" ]; then
   _log "ERROR: size is $size, expected 0"
   piladb_stop $pid
   exit 1
fi

empty=$(piladb_EMPTY db1 mystack1)
if [ "$empty" != true ]; then
   _log "ERROR: empty is $empty, expected true"
   piladb_stop $pid
   exit 1
fi

piladb_delete_stack db1 mystack2

number_of_stacks=$(piladb_database db1 | jq '.number_of_stacks')
if [ "$number_of_stacks" -ne "2" ]; then
   _log "ERROR: number of stacks is $number_of_stacks, expected 2"
   piladb_stop $pid
   exit 1
fi

# test MAX_SIZE_STACK and FULL

piladb_config_set MAX_STACK_SIZE 3
piladb_create_stack db1 maxsize

full=$(piladb_FULL db1 maxsize)
if [ "$full" = true ]; then
   _log "ERROR: full is $full, expected false"
   piladb_stop $pid
   exit 1
fi

piladb_PUSH db1 maxsize 1
piladb_PUSH db1 maxsize 2
piladb_PUSH db1 maxsize 3

full=$(piladb_FULL db1 maxsize)
if [ "$full" != true ]; then
   _log "ERROR: full is $full, expected true"
   piladb_stop $pid
   exit 1
fi

# test PUSH_WHEN_FULL

piladb_PUSH db1 maxsize 4

peek=$(piladb_PEEK db1 maxsize | jq '.element')
if [ "$peek" != 3 ]; then
   _log "ERROR: peek is $peek, expected 3"
   piladb_stop $pid
   exit 1
fi

piladb_config_set PUSH_WHEN_FULL true

piladb_PUSH db1 maxsize 4

peek=$(piladb_PEEK db1 maxsize | jq '.element')
if [ "$peek" != 4 ]; then
   _log "ERROR: peek is $peek, expected 4"
   piladb_stop $pid
   exit 1
fi

size=$(piladb_SIZE db1 maxsize)
if [ "$size" -ne "3" ]; then
   _log "ERROR: size is $size, expected 3"
   piladb_stop $pid
   exit 1
fi

# cleanup

piladb_stop $pid
_log "all good! ✅"
