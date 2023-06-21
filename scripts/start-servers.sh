#!/bin/bash

set -x

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
START_SERVERS_DIR=$PWD

cd ../../../.. # we are now at root of repo

## if you set pipefail here, the script will die when one of the greps below doesn't find anything. Don't do it.
set -eu

echo -e "\n****** delete any data out of the empty tenant"
psql -v tenant_name=empty -v user_created=true -v fdl=false <config-ui/db/sql/clear-tenant-data.sql
psql -v tenant_name=empty -v user_created=true -v fdl=false <config-ui/db/sql/clear-tenant-data.sql

echo -e "\n****** start config ui if not running"
PID=$(lsof -t -i :3001 -sTCP:LISTEN) || true
if [[ -z "$PID" ]]; then
    pushd config-ui
    if [[ ! -e .next/BUILD_ID ]]; then
        npm run build
    fi
    popd
    regression/start-config-ui.sh
fi

echo -e "\n****** start webhook if not running"
PID=$(lsof -t -i :3002 -sTCP:LISTEN) || true
if [[ -z "$PID" ]]; then
    regression/start-webhook.sh
fi

echo -e "\n****** start the iserver"
regression/kill-iserver.sh
PID=$(lsof -t -i :3004 -sTCP:LISTEN) || true
if [[ -z "$PID" ]]; then
    TENANT=EMPTY regression/start-iserver.sh
fi

cd $START_SERVERS_DIR

echo -e "\n****** push the fdl"
wget --content-on-error -O- --header='Content-Type:text/plain' --post-file ../Tests/Fixtures/TestExample.fdl \
    'http://localhost:3002/fdlpush?token=778f73ae6efd1af4f958889c&env=a9ff6797-4598-4d18-b040-f024d112f112'

for pid in $(pgrep -P $$); do
    echo $pid
    disown $pid
done
