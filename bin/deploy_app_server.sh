#!/bin/sh

ANSIBLE=/usr/bin/ansible

$ANSIBLE-playbook $HOME/ansible/deploy_app_server.yaml -i $HOME/ansible/hosts --private-key $HOME/.ssh/aws_demo.pem
