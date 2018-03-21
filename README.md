piladb Shell Client [![osw](https://img.shields.io/badge/%E2%89%85osw-supported-blue.svg)](http://oscillating.works) [![Build Status](https://travis-ci.org/oscillatingworks/piladb-sh.svg?branch=master)](https://travis-ci.org/oscillatingworks/piladb-sh)
===================

`piladb.sh` is a set of utilities to interact with [**piladb**](https://www.piladb.org)
from the command line or shell scripts. It aims to make simple interactions with a piladb server
in an easy and fast way.

Requirements
------------

* Unix/Linux machine with bash, zsh or similar shell in use.
* HTTPie: https://github.com/jkbrzt/httpie#installation
* `PILADB_HOST` set for remote server, e.g. export `PILADB_HOST=piladb.example.org`

Installation
------------

```bash
source <(curl -s https://raw.githubusercontent.com/oscillatingworks/piladb-sh/master/piladb.sh)
```

Now type `piladb_[TAB]` and you will see a bunch of piladb related commands.

Usage
-----

See `piladb_help`.

Tests
-----

Run `bash piladb_test.sh`.

Examples
--------

Start a local server, create a database and a stack, `PUSH` random number
from 1 to 10, and stop the server:

```bash
#!/bin/bash

piladb_start

piladb_create_database MYDB
piladb_create_stack MYDB MYSTACK

piladb_PUSH MYDB MYSTACK $(( ( RANDOM % 10 )))
piladb_PUSH MYDB MYSTACK '"A string"'
piladb_PUSH MYDB MYSTACK true
piladb_PUSH MYDB MYSTACK '{"country":"ES"}'

piladb_POP MYDB MYSTACK

piladb_stop
```

Connect to a remote server, check status:

```bash
export PILADB_HOST=mypiladb.example.com

piladb_status
```

Download latest version of `pilad` and start server:

```bash
piladb_download
piladb_start
```

License
-------

MIT
