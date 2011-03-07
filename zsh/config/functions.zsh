# jump to previous directory by number or last visited:
back() {
  case $1 in
  [a-zA-Z]) : ;;
  <->) pushd -q +$1 ;;
  l) dirs -lpv|sed '2 s|$| \[last\]|' ;;
  *) pushd -q -
  esac
}

# copy and follow file to new dir:
cpf() {
if [[ -d $*[-1] ]]; then
  cp $* && cd $*[-1]
elif [[ -d ${*[-1]%/*} ]]; then
  cp $* && cd ${*[-1]%/*}
fi
}

# move and follow file to new dir:
mvf() {
if [[ -d $*[-1] ]]; then
  mv $* && cd $*[-1]
elif [[ -d ${*[-1]%/*} ]]; then
  mv $* && cd ${*[-1]%/*}
fi
}

# make folder and chdir into it:
mkdirf() {
    mkdir -p $@ && 
    cd "$@[-1]"
}

# change dir and ls
cdl() {
    builtin cd $@ && ls
}
