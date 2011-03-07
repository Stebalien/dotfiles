use strict;

use Irssi qw(command_bind signal_add);
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';

%IRSSI = (
    authors => 'Steven',
    contact => 'steven@stebalien.com',
    name    => 'Gnome Keyring',
    license => 'GPLv3',
    changed => $VERSION,
    commands => 'gkey_ident',
);

sub gnome_keyring_identify {
    my $win = @_[1];
    my $pw = `pykeyring get password "irc://$win->{chatnet}"`;
    $win->command("MSG NickServ identify $pw");
    $win->command("WINDOW goto NickServ");
    $win->command("WINDOW close");
}

Irssi::command_bind('gkey_login', 'gnome_keyring_identify');

