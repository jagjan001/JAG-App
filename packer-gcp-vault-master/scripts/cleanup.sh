#!/bin/bash

set -e

rm -rf /etc/machine-id
touch /etc/machine-id

yum clean all
