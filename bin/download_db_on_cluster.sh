#!/bin/sh

ANSIBLE=/usr/bin/ansible

$ANSIBLE-playbook $HOME/ansible/download_app_db.yaml -i $HOME/ansible/hosts --private-key $HOME/.ssh/aws_demo.pem
