#!/bin/bash
# filename: install_zsh.sh
# description: install zsh and oh-my-zsh tools
# author: jason zhao
# version: 1.0_2016.4.16
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++

# cmd return code
check_ok(){
    if [[ $? -ne 0 ]]; then
        echo -e "\033[31m$1\033[00m" 1>&2
        exit 1
    fi
}

# success information display
succ_info(){
    echo -e "\033[32m$1\033[00m"
}

# install zsh and autojump-plugin
cd ~
tmp=$(which yum 2>/dev/null) && inst_cmd=$tmp
tmp=$(which apt-get 2>/dev/null) && inst_cmd=$tmp
echo -e "install zsh and autojump ..."
sudo $inst_cmd install -y zsh 
check_ok "ERROR: use \"sudo\" or root user to install!"
sudo $inst_cmd install -y autojump
check_ok "ERROR: use \"sudo\" or root user to install!"
if [[ $(basename $inst_cmd) == "yum" ]]; then
    sudo $inst_cmd install -y autojump-zsh
    check_ok "ERROR: use \"sudo\" or root user to install!"
fi

# download and set oh-my-zsh
if [[ -d ~/.oh-my-zsh ]]; then
    echo 'DIRECTORY: ".oh-my-zsh" has been exist!'
    exit 1
fi
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
check_ok "ERROR: download oh-my-zsh failed!"
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
check_ok "ERROR: can't create \"~/.zshrc\" !"
succ_info "install oh-my-zsh in \"~/.oh-my-zsh\" and \"~/.zshrc\" complete!"

# add important alias and set autojump
cat << EOF >> ~/.zshrc
#
# user defines.
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'
alias sudo='sudo '
EOF
path=$(sudo find / -name '*autojump.sh*' 2>/dev/null |grep 'autojump.sh'); check_ok "ERROR: can't find autojump.sh!"
echo "[[ -s $path ]] && . $path" >> ~/.zshrc
sed -i 's/ZSH_THEME=.*/ZSH_THEME="bira"/g' ~/.zshrc
sed -i 's/^plugins=(git)/plugins=(git autojump)/g' ~/.zshrc

# change login user prompt
wget https://raw.githubusercontent.com/jasonz666/my-configs/master/.zsh_bira_theme_ps1.txt
check_ok "ERROR: download PS1 file failed!"
if [[ $(whoami) == "root" ]]; then
    grep -A2 '# root' .zsh_bira_theme_ps1.txt >> ~/.zshrc
else
    grep -A2 '# normal' .zsh_bira_theme_ps1.txt >> ~/.zshrc
fi
succ_info "set alias, autojump-plugin and zsh-theme complete!"

# change sh
echo -e "input current login user's password to change shell to zsh:"
while :; do
    chsh -s /bin/zsh
    if [[ $? -eq 0 ]]; then
        break
    fi
done
exit 0
