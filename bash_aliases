# Program packages:
# pikaur -Syu --needed lsd mc reflector expac fzf bash-completion etc-update less jq

# https://wiki.archlinux.org/title/Bash#Aliases
## ALIASES MANAGEMENT
alias baupdate=". ~/.bash_aliases"
alias brupdate=". ~/.bashrc"

# https://wiki.archlinux.org/title/Systemd#Using_units
## SYSTEMD MANAGEMENT
#IsSerUser () { [ "$(systemctl --user show -pLoadError $1)" == "LoadError=" ] && echo "U"; }
Sstatus   () { systemctl --user status --no-pager -l "$1" 2>/dev/null || systemctl status --no-pager -l "$1"; }
Systemctl () { A="$1"; shift; (systemctl --user "$A" "$@" 2>/dev/null || sudo systemctl "$A" "$@" ) && wait3sec "Success! Wait 3 sec"; Sstatus "${!#}"; }
Sstart    () { Systemctl start "$@"; }
Sstop     () { Systemctl stop "$@"; }
Srestart  () { Systemctl restart "$@"; }
Sdisable  () { Systemctl disable "$@"; }

Senable   () { sudo systemctl enable "$@"; }
alias Stimers="systemctl list-timers --all"
alias Slists="systemctl list-units --type=service --all --no-pager"

## TUNING PROGRAMS
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias grep="grep --color=auto"

## SHORTS
alias openports="sudo ss -ntulp"
alias x="exit"
alias gethash="tr -dc 'a-z0-9' < /dev/urandom | dd bs=1 count=32 2>/dev/null && echo"
alias boottime="systemd-analyze && systemd-analyze blame --no-pager"

## SHORTS: EXTERNAL PROGRAMS
alias ls="lsd --group-directories-first -F"
alias 0x0="curl -4 -F file=@- https://0x0.st"
alias mc="EDITOR=micro mc"
# https://wiki.archlinux.org/title/Reflector
alias umirror="sudo reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist"

## OTHER FUNCTIONS
backup  () { cp "$1"{,.backup}; }
sbackup () { sudo cp "$1"{,.backup}; }
cd      () { builtin cd "$@" && ls; }
wait3sec() { echo -n "$1"; for i in \{1 2 3\}; do echo -n "."; sleep 1; done; echo; }
line    () { l=$1"p"; shift; sed -n $l $@; }

## PIKAUR MANAGEMENT
# https://wiki.archlinux.org/title/Fzf#Pacman
Install () { [ "$#" -eq 0 ] && echo "Usage: Install <keyword or package(s)>" || ([ "$#" -eq 1 ] && (pikaur -Sslq $1 | sort -u | fzf -q $1 -i -m --reverse --preview 'pikaur -Sii {1}' --preview-window right:60%:wrap | xargs -ro pikaur -S --needed --noedit) || pikaur -S --needed --noedit $@); }
# https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Packages_and_dependencies
Purge	() { [ "$#" -eq 0 ] && (comm -23 <((pacman -Qqen; pacman -Qqm)| sort) <((expac -l '\n' '%E' base-devel; expac -l '\n' '%E' base) | sort -u) | sort -u | fzf -i -m --reverse --preview 'pikaur -Sii {1}' --preview-window right:80%:wrap | xargs -ro pikaur -Rsc) || pikaur -Rsc $@; }
alias Update="pikaur -Su --noedit"
alias Upgrade="pikaur -Syu --noedit"
alias Ccache="pikaur -Sc"

#SYSTEM MAINTAINING
alias getnews="echo; echo -ne '\033[0;34m:: \033[0m\033[1mMirror: '; grep -m1 Server /etc/pacman.d/mirrorlist | cut  -d'/' -f3; echo -e '\033[0m'; pikaur -Syu --noedit"
# https://wiki.archlinux.org/title/Pacman/Pacnew_and_Pacsave#.pacnew
alias whatsnew="find /etc -name *.pacnew 2>/dev/null | sed 's/.pacnew//' | fzf --reverse --preview 'diff -y --suppress-common-lines {1} {1}.pacnew' --preview-window right:78%:wrap | xargs -ro sudo etc-update"

## INSTANCE SCRIPTS ##
source /etc/instance.conf
INSTANCESCRIPTWAY="$PATHINSTANCE/scripts"
alias ins="cd $PATHINSTANCE"
alias sc='echo -e "Y\nY" | $INSTANCESCRIPTWAY/cleansystem.sh'
alias packages="$INSTANCESCRIPTWAY/packages.sh"
alias age="$INSTANCESCRIPTWAY/age.sh"
alias ustat="watch -n 10 $INSTANCESCRIPTWAY/serverstatus.sh"
alias topmem="$INSTANCESCRIPTWAY/topmem.sh"
alias bugspaces="grep -RnE ' $' 2>/dev/null"

if [ "$(mount | grep -o ' / type btrfs')" != "" ]; then
    alias snapctl="yabsnap list-json | jq -r '.trigger+\" \"+.file.timestamp' | fzf -m --reverse --preview '$INSTANCESCRIPTWAY/snaplist.sh {2}'  --preview-window right:70%:wrap | xargs -I{} echo {} | cut -d' ' -f2 | xargs -I{} sudo yabsnap delete {}"
    alias uisorescue="$INSTANCESCRIPTWAY/uisorescue.sh"
else
    alias {snapctl,uisorescue}="echo 'This alias works with btrfs partitions only'"
fi

## SENSITIVE DATAS: LOGINS, ADDRESSES ETC.
if [ -f "$INSTANCESCRIPTWAY/sensitive.sh" ]; then
   source "$INSTANCESCRIPTWAY/sensitive.sh"
fi
