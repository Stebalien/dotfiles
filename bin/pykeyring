#!/usr/bin/python2
"""
Creates a very easy to use gnome-keyring interface.
When run as a command, it interactivly adds items to the keyring.
"""
import gnomekeyring as gkey
from sys import argv
from sys import exit

class Keyring(object):
    """
    A simple keyring class. It requires a `server' uri and a `protocol'.
    """
    def __init__(self, server, protocol):
        self._server = server
        self._protocol = protocol
        self._keyring = gkey.get_default_keyring_sync()

    def has_credentials(self):
        """
        Check if a key exists.
        """
        try:
            attrs = {"server": self._server, "protocol": self._protocol}
            items = gkey.find_items_sync(gkey.ITEM_NETWORK_PASSWORD, attrs)
            return len(items) > 0
        except gkey.DeniedError:
            return False

    def get_credentials(self):
        """
        Get a key.
        """
        attrs = {"server": self._server, "protocol": self._protocol}
        items = gkey.find_items_sync(gkey.ITEM_NETWORK_PASSWORD, attrs)
        return (items[0].attributes["user"], items[0].secret)

    def set_credentials(self, user, password):
        """
        Set a key.
        """
        attrs = {
                "user": user,
                "server": self._server,
                "protocol": self._protocol,
            }
        gkey.item_create_sync(gkey.get_default_keyring_sync(),
                              gkey.ITEM_NETWORK_PASSWORD,
                              "%s://%s@%s" % (
                                  attrs["protocol"], 
                                  attrs["user"], 
                                  attrs["server"]
                              ), 
                              attrs, 
                              password, 
                              True
                             )

def get_username(server, protocol):
    """
    Get a username for a server and protocol.
    """
    keyring = Keyring(server, protocol)
    username = keyring.get_credentials()[0]
    return username

def get_password(server, protocol):
    """
    Get a password for a server and protocol.
    """
    keyring = Keyring(server, protocol)
    password = keyring.get_credentials()[1]
    return password

def cli_add_key():
    """
    Generate a key based on user input.
    """
    import getpass
    proto = raw_input("Protocol: ")
    server = raw_input("Server: ")
    username = raw_input("Username: ")
    password = getpass.getpass(prompt="Password: ")
    keyring = Keyring(server, proto)

    keyring.set_credentials(username, password)

if __name__ == "__main__":
    if len(argv) == 4 and argv[1] == "get":
        proto, server = argv[3].split(':')
        server = server.strip('/')
        try:
            if argv[2] == "password":
                print(get_password(server, proto))
            elif argv[2] == "user":
                print(get_username(server, proto))
        except gkey.NoMatchError:
            print("No matching credentials.")
            exit(1)
    elif len(argv) == 1 or (len(argv) == 2 and argv[1] == "add"):
        cli_add_key()
    else:
        print("Invalid Command: %s %s" % (argv[0], " ".join(argv[1:])))

