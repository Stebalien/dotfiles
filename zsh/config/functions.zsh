# go up X amount of directories:
function up(){
  local arg=${1:-1};
  while [ $arg -gt 0 ]; do
    cd .. >&/dev/null;
    arg=$(($arg - 1));
  done
}

# jump to previous directory by number or last visited:
function back() {
  case $1 in
  [a-zA-Z]) : ;;
  <->) pushd -q +$1 ;;
  l) dirs -lpv|sed '2 s|$| \[last\]|' ;;
  *) pushd -q -
  esac
}

# copy and follow file to new dir:
function cpf() {
if [[ -d $*[-1] ]]; then
  cp $* && cd $*[-1]
elif [[ -d ${*[-1]%/*} ]]; then
  cp $* && cd ${*[-1]%/*}
fi
}

# move and follow file to new dir:
function mvf() {
if [[ -d $*[-1] ]]; then
  mv $* && cd $*[-1]
elif [[ -d ${*[-1]%/*} ]]; then
  mv $* && cd ${*[-1]%/*}
fi
}

# make folder and chdir into it:
function mkdirf() {
    mkdir -p $@ && 
    cd "$@[-1]"
}

# change dir and ls
function cdl() {
    cd $@ && ls
}

