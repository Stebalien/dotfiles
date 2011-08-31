#!/bin/bash
for file in $XDG_CONFIG_HOME/mutt/*.accountrc; do
    account=$(basename $file .accountrc)
    echo -n "folder-hook $account/* source $XDG_CONFIG_HOME/mutt/$account.accountrc; "
    echo -n "mailboxes =$account"
    for folder in $HOME/.mail/$account/*; do
        echo -n " +$account/$(basename $folder)"
    done
    echo -n '; '
done
echo 'source $XDG_CONFIG_HOME/mutt/default-account'
