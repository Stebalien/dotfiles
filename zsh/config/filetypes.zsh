autoload -U zsh-mime-setup
zstyle ':mime:.pkg.tar.xz:' handler 'sudo pacman-color -U %s'
zstyle ':mime:.pkg.tar.xz:' flags 'needsterminal'

zstyle ':mime:.src.tar.gz:' handler '/usr/bin/aunpack %s'
zstyle ':mime:.src.tar.gz:' flags 'needsterminal'

zstyle ':mime:.jar:' handler '/usr/bin/java -jar %s'
zsh-mime-setup

