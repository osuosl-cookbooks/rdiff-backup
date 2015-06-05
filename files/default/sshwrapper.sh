#!/bin/sh

# This wrapper is used to restrict the number of commands that can be run over
# SSH, since authorized_keys only accepts one command, and without variable
# arguments.

case "$SSH_ORIGINAL_COMMAND" in
  "sudo rdiff-backup --server --restrict-read-only /")
    sudo rdiff-backup --server --restrict-read-only /;;
  "mysql -e SHOW\ DATABASES"*)
    eval $SSH_ORIGINAL_COMMAND;;
  "mysqldump"*)
    eval $SSH_ORIGINAL_COMMAND;;
esac
