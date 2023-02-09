#!/bin/bash

set -e
set -x

# Check if git is installed
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi

# Check if the repo URL is provided
if [ $# -eq 0 ]; then
  echo "Error: No repository URL provided." >&2
  exit 1
fi

# Parse the command line arguments
install=false
while [ $# -gt 0 ]; do
  case "$1" in
    -i|--install)
      install=true
      ;;
    *)
      repo_url=$1
      ;;
  esac
  shift
done

# Clone the repository
repo_name=$(echo "$repo_url" | awk -F/ '{print $NF}' | sed -e 's/.git$//')
git clone --recursive "$repo_url" "$repo_name"
cd "$repo_name"

# Check for makefile, Makefile, Makefile.am, configure, or configure.ac
if [ -f "makefile" ] || [ -f "Makefile" ] || [ -f "Makefile.am" ] || [ -f "configure" ] || [ -f "configure.ac" ]; then
  if [ -f "Makefile.am" ] || [ -f "configure.ac" ]; then
    autoreconf -i
  fi
  mkdir -p build
  cd build
  ../configure
  make
  $install && sudo make install
  cd ..
# Check for cmake file
elif [ -f "CMakeLists.txt" ]; then
  mkdir -p build
  cd build
  cmake ..
  make
  $install && sudo make install
  cd ..
# Check for setup.py
elif [ -f "setup.py" ]; then
  python3 setup.py build
  $install && sudo python3 setup.py install
else
  if [ -f "INSTALL" ] || [ -f "INSTALL.md" ]; then
    cat "INSTALL" || cat "INSTALL.md"
  elif [ -f "README" ] || [ -f "README.md" ]; then
    cat "README" || cat "README.md"
  else
    echo "Error: Unable to find a build system or installation instructions." >&2
    exit 1
  fi
fi
