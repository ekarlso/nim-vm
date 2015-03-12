#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

nimvm_has() {
  type "$1" > /dev/null 2>&1
}

METHOD=${METHOD:-}

NIMVM_DIR=${NIMVM_DIR:-$HOME/.nimvm}

nimvm_latest_version() {
  echo "v0.3.0"
}

#
# Outputs the location to NIMVM depending on:
# * The availability of $NIMVM_SOURCE
# * The method used ("script" or "git" in the script, defaults to "git")
#
nimvm_source() {
  local NIMVM_METHOD="$1"
  local NIMVM_SOURCE_URL="$NIMVM_SOURCE"

  if [ "_$NIMVM_METHOD" = "_script" ]; then
      NIMVM_SOURCE_URL="https://raw.githubusercontent.com/ekarlso/nim-vm/$(nimvm_latest_version)/nim-vm"
  elif [ -z "$NIMVM_SOURCE_URL" ]; then
    if [ "_$NIMVM_METHOD" = "_git" ] || [ -z "$NIMVM_METHOD" ]; then
      NIMVM_SOURCE_URL="https://github.com/ekarlso/nim-vm.git"
    else
      echo >&2 "Unexpected value \"$NIMVM_METHOD\" for \$NIMVM_METHOD"
      return 1
    fi
  fi
  echo "$NIMVM_SOURCE_URL"
}

nimvm_download() {
  if nimvm_has "curl"; then
    curl $*
  elif nimvm_has "wget"; then
    # Emulate curl with wget
    ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                           -e 's/-L //' \
                           -e 's/-I /--server-response /' \
                           -e 's/-s /-q /' \
                           -e 's/-o /-O /' \
                           -e 's/-C - /-c /')
    wget $ARGS
  fi
}

install_nimvm_as_symlink() {
  local bindir=$NIMVM_DIR/bin

  # This assumes we're installing from the repository in symlink mode. useful for dev / test or if you want to be on the latest version of the repository
  if [ -x "$NIMVM_DIR/nim-vm" ]; then
    die $LINENO "nim-vm is already installed at $NIMVM_DIR."
  fi

  mkdir -p $bindir
  ln -nfs $DIR/../bin/nim-vm $bindir
}

install_nimvm_from_git() {
  if [ -d "$NIMVM_DIR/.git" ]; then
    echo "=> nim-vm is already installed in $NIMVM_DIR, trying to update using git"
    printf "\r=> "
    cd "$NIMVM_DIR" && (command git fetch 2> /dev/null || {
      echo >&2 "Failed to update nimvm, run 'git fetch' in $NIMVM_DIR yourself." && exit 1
    })
  else
    # Cloning to $NIMVM_DIR
    echo "=> Downloading nimvm from git to '$NIMVM_DIR'"
    printf "\r=> "
    mkdir -p "$NIMVM_DIR"
    command git clone "$(nimvm_source git)" "$NIMVM_DIR"
  fi
  cd "$NIMVM_DIR" && command git checkout --quiet $(nimvm_latest_version) && command git branch --quiet -D master >/dev/null 2>&1
  return
}

install_nimvm_as_script() {
  local nimvm_source=$(nimvm_source script)

  local bindir=$NIMVM_DIR/bin
  # Downloading to $NVM_DIR
  mkdir -p "$bindir"

  if [ -f "$bindir/nim-vm" ]; then
    echo "=> nim-vm is already installed in $bindir, trying to update the script"
  else
    echo "=> Downloading nim-vm as script to '$bindir'"
  fi
  nimvm_download -s "$nimvm_source" -o "$bindir/nim-vm" || {
    echo >&2 "Failed to download '$nimvm_source'"
    return 1
  }

  chmod +x $bindir/nim-vm
}

#
# Detect profile file if not specified as environment variable
# (eg: PROFILE=~/.myprofile)
# The echo'ed path is guaranteed to be an existing file
# Otherwise, an empty string is returned
#
nimvm_detect_profile() {
  if [ -f "$PROFILE" ]; then
    echo "$PROFILE"
  elif [ -f "$HOME/.bashrc" ]; then
    echo "$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    echo "$HOME/.bash_profile"
  elif [ -f "$HOME/.zshrc" ]; then
    echo "$HOME/.zshrc"
  elif [ -f "$HOME/.profile" ]; then
    echo "$HOME/.profile"
  fi
}

nimvm_do_install() {
  if [ -z "$METHOD" ]; then
    # Autodetect install method
    if nimvm_has "git"; then
      install_nimvm_from_git
    elif nimvm_has "nimvm_download"; then
      install_nimvm_as_script
    else
      echo >&2 "You need git, curl, or wget to install nvm"
      exit 1
    fi
  elif [ "~$METHOD" = "~git" ]; then
    if ! nimvm_has "git"; then
      echo >&2 "You need git to install nim-vm"
      exit 1
    fi
    install_nimvm_from_git
  elif [ "~$METHOD" = "~script" ]; then
    if ! nimvm_has "nimvm_download"; then
      echo >&2 "You need curl or wget to install nim-vm"
      exit 1
    fi
    install_nimvm_as_script
  elif [ "~$METHOD" = "~symlink" ]; then
    install_nimvm_as_symlink
  else
    echo "Unsupported method $METHOD."
    exit 1
  fi

  local NIMVM_PROFILE
  NIMVM_PROFILE=$(nimvm_detect_profile)

  SOURCE_STR="export PATH=\$PATH:\"$NIMVM_DIR/bin\""

  if [ -z "$NIMVM_PROFILE" ] ; then
    echo "=> Profile not found. Tried $NIMVM_PROFILE (as defined in \$PROFILE), ~/.bashrc, ~/.bash_profile, ~/.zshrc, and ~/.profile."
    echo "=> Create one of them and run this script again"
    echo "=> Create it (touch $NIMVM_PROFILE) and run this script again"
    echo "   OR"
    echo "=> Append the following lines to the correct file yourself:"
    printf "\n$SOURCE_STR"
    echo
  else
    if ! grep -qc "$SOURCE_STR" "$NIMVM_PROFILE"; then
      echo "=> Appending source string to $NIMVM_PROFILE"
      printf "\n$SOURCE_STR\n" >> "$NIMVM_PROFILE"
    else
      echo "=> Source string already in $NIMVM_PROFILE"
    fi
  fi

  nimvm_reset
}

#
# Unsets the various functions defined
# during the execution of the install script
#
nimvm_reset() {
  unset -f nimvm_reset nimvm_has nimvm_latest_version \
    nimvm_source nimvm_download install_nimvm_as_script install_nimvm_from_git \
    nimvm_detect_profile nimvm_check_global_modules nimvm_do_install
}

nimvm_do_install
