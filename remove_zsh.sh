#!/bin/bash
# filename: remove_zsh.sh
# description: remove oh-my-zsh and set back to bash
# author: jason zhao
# version: 1.0_2016.04.17
#+++++++++++++++++++++++++++++++++++++++++++++++++++++

# cmd return code
check_ok(){
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31m$1\033[00m" 1>&2
        exit 1
    fi
}

# rm oh-my-zsh .z*
cd ~
rm -rf ~/.oh-my-zsh/ .zsh* .zcompdump*; check_ok "ERROR: remove files failed!"

# set to bash
echo -e "input current login user's password to change shell to bash:"
while :; do
    chsh -s /bin/bash
    if [[ $? -eq 0 ]]; then
        break
    fi
done
echo "INFO: remove oh-my-zsh successfully, but DON'T REMOVE \"zsh\" cmd!"
exit 0
