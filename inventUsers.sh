#!/usr/bin/env bash

for i in $(seq 10 11)
do
    echo "Creating user test$i"
    useradd -g garbage -s "/sbin/nologin" -M test$i
done



