#!/bin/sh
apt-get update
apt-get install -y ansible python3-pip
pip3 install "azure==2.0.0rc5"
