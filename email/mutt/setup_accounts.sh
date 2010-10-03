#!/bin/bash
MAIL_FOLDER=$HOME/.mail
for file in $XDG_CONFIG_HOME/mutt/*.accountrc; do
    account=$(basename $file .accountrc)
    echo -n "folder-hook $account/* source $XDG_CONFIG_HOME/mutt/$account.accountrc; "
    echo -n "mailboxes =$account"
    for folder in $MAIL_FOLDER/$account/*; do
        echo -n " +$account/$(basename $folder)"
    done
    echo -n '; '
done
echo -n 'source $XDG_CONFIG_HOME/mutt/default-account; '
echo "exec next-unread-mailbox"
