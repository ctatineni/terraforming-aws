#!/bin/bash
set -e

source ./set-bosh-proxy.sh

# bosh manifest -d concourse
credhub login
credhub import --file ./credhub-import-pks.yml
