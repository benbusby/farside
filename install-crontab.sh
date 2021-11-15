#!/bin/sh
# Install crontab to run update script

SCRIPT_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

(crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_DIR/update.sh") | crontab -
