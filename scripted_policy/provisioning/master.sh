#!/bin/bash

apt-get update && \
apt install -y python-pip mc && \
pip install testinfra pytest-xdist paramiko
