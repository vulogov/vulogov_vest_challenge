#!/bin/sh

ANSIBLE=/usr/bin/ansible

$ANSIBLE-playbook $HOME/ansible/start_server.yaml -i $HOME/ansible/hosts --private-key $HOME/.ssh/aws_demo.pem
