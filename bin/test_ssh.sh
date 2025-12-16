#!/bin/sh

ANSIBLE=/usr/bin/ansible

$ANSIBLE-playbook $HOME/ansible/test_ssh.yaml -i $HOME/ansible/hosts --private-key $HOME/.ssh/aws_demo.pem
