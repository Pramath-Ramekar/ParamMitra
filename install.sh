#!/usr/bin/env bash

set -e

echo "[+] Installing ParamMitra dependencies"

sudo apt update

sudo apt install -y \
  python3 \
  python3-pip \
  golang \
  parallel \
  git

# Go tools
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/qsreplace@latest
go install github.com/ffuf/x8@latest

# Python tools
pip3 install --user paramspider arjun linkfinder

# JSParser
git clone https://github.com/nahamsec/JSParser.git ~/JSParser || true
sudo ln -sf ~/JSParser/JSParser.py /usr/local/bin/JSParser

echo '[+] export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc

echo "[✓] Installation complete"
