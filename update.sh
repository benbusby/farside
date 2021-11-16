#!/bin/sh

SCRIPT_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

cd "$SCRIPT_DIR"
FARSIDE_NO_ROUTER=1 mix run update.exs
