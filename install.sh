#! /bin/bash

set -e
self=$(readlink -f $0)
if [ -z $DOTDIR ]; then 
  DOTDIR=$(dirname $self)
  read -p "Install into $DOTDIR (y/N)? " choice
  case "$choice" in
    y|Y ) export DOTDIR=$DOTDIR ;;
    * ) echo "ok, exiting." && exit 1 ;;
  esac
fi
pushd $DOTDIR

HOME=$(readlink -f ~)
echo "installing into: $HOME"

PACMAN=$((apt --version > /dev/null 2>&1 && echo "apt") || (brew --version > /dev/null 2>&1 && echo "brew"))

function should_skip {
  local prefix='./__'
  local test="${1#$prefix}"
  [ "$1" == './install.sh' ] || [ "$1" == './README.md' ] || [ "$1" == "./LICENSE" ] || [ "$test" != "$1" ]
  return $?
}

function visit {
  local dir=$1
  local rootdir=$2
#  echo "visit $dir (root = $rootdir)"
  for item in `ls $dir`; do
    if should_skip "$dir/$item" ; then
      echo "SKIPPING $dir/$item"
      continue
    fi
    if [ -d "$dir/$item" ]; then
      if [ $rootdir = "." ]; then
        visit $item $item
      else
        visit "$dir/$item" $rootdir
      fi
    else
      link "$dir/$item" $rootdir
    fi
  done
}

function link {
  local root=$2
  local src=$1
  local targetdir=$(dirname $src)/
  local filename=$(basename $src)
  local targetroot=$(readlink -f ~/$root)

  if [ $root = "." ]; then 
    filename=".$filename"
    targetdir=""
  else 
    if [ ! -d $targetroot ]; then
      targetdir=".$targetdir"
    fi
    if [ ! -d $HOME/$targetdir ]; then
      echo "mkdir: $HOME/$targetdir"
      mkdir -p $HOME/$targetdir
    fi
  fi
  local targetfile="$HOME/$targetdir$filename"

  if [ -f $targetfile ] || [ -h $targetfile ]; then
    if [ ! -h $targetfile ]; then
    echo "backing up existing file: $targetfile"
    local backup=$targetfile".backup"
      rm $backup > /dev/null 2>&1 && echo "previous backup removed" || echo "no previous backup"
      mv $targetfile $backup
    fi
    rm $targetfile > /dev/null 2>&1 || echo "removed old version"
  else
    echo "target file doesn't exist: $targetfile"
  fi

  echo "installing: $targetfile"

  ln -s $(readlink -f $src) $targetfile
}

function apply_profile {
  [ ! -f "$1" ] && echo "$1 not found" && return || echo "installing $1..."
  local mstart="### DOTPATCH START"
  local mend="### DOTPATCH END"
  
  local profile_file="$HOME/.bash_profile"
  
  if [ ! -f $profile_file ]; then
    if [ -f "$HOME/.bashrc" ]; then
      profile_file="$HOME/.bashrc"
    else
      >&2 echo "unable to install bash autoload"
      exit 1
    fi 
  fi

  echo "Patching $profile_file"
  local patched="$profile_file.patched"
  [ -f $patched ] && rm $patched
  touch $patched

  local patchstatus=0
  while IFS= read -r line; do
    case $patchstatus in
      0)
        local ismstart="${line#$mstart}"
        if [ "$ismstart" != "$line" ]; then
          patchstatus=1
        fi
        echo "${line}" >> $patched
        ;; 
      1) 
        local ismend="${line#$mend}"
        if [ "$ismend" != "$line" ]; then
          cat $1 >> $patched
          echo "# dotman directory"
          echo "export DOTDIR=$DOTDIR"
          echo "${line}" >> $patched
          patchstatus=2
        fi
        ;;
      *) 
        echo "${line}" >> $patched
    esac
  done < $profile_file

  if [ "$patchstatus" == "0" ]; then 
    echo "new install? adding markers to the profile file"
    echo $mstart >> $patched
    cat $1 >> $patched
    echo $mend >> $patched
  fi

  echo "Backing up current profile..."
  cp $profile_file "$profile_file.back"
  echo "Installing updated version..."
  cat $patched > $profile_file
  rm $patched
}

function autoinstall {
  echo "Using $PACMAN to auto-install configured packages"
  while IFS= read -r item; do
    local test="${item#$PACMAN}"
    if [ "$test" == "$item" ]; then
      test="${item#\*}"
      if [ "$test" == "$item" ]; then
        echo "$item: (SKIP)"
        continue
      else 
        item="${test# }"
      fi
    fi
    echo "$item:"
    $item | awk '{print "->", $0}'
  done < $1
}

mkdir -p ~/bin


autoinstall __install
apply_profile __profile
visit . .
popd

