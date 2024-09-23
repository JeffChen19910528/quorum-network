#!/bin/bash

# Quorum Installation Script

# Function to check and install dependencies
check_and_install_dependency() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 is not installed. Installing..."
        sudo apt update
        sudo apt install -y $1
    else
        echo "$1 is already installed"
    fi
}

# Check dependencies
echo "Checking dependencies..."
check_and_install_dependency git
check_and_install_dependency golang-go
check_and_install_dependency make

# Set up Go environment variables
export GOROOT=/usr/lib/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Clone Quorum repository
echo "Cloning Quorum repository..."
git clone https://github.com/ConsenSys/quorum.git
cd quorum

# Compile Quorum
echo "Compiling Quorum..."
make all

# Set up environment variables
echo "Setting up environment variables..."
QUORUM_PATH=$(pwd)/build/bin
echo "export PATH=\$PATH:$QUORUM_PATH" >> ~/.bashrc
echo "export PATH=\$PATH:$QUORUM_PATH" >> ~/.zshrc

# Apply changes to the current shell
export PATH=$PATH:$QUORUM_PATH

# Verify installation
echo "Verifying installation..."
if geth version
then
    echo "Quorum installation successful!"
    echo "Please run 'source ~/.bashrc' or restart your terminal to apply the environment variable changes."
else
    echo "Quorum installation may not have been successful. Please check the error messages."
fi