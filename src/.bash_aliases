# Make file system utilities friendlier
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias cp='cp -iv'
alias mv='mv -iv'
alias less='less -R'

# Configure useful programs
alias lp='/usr/bin/lp -o sides=two-sided-long-edge -o media=letter -o cpi=16 -o lpi=10'
alias lpb='/usr/bin/lp -o sides=two-sided-long-edge -o media=letter -o cpi=12 -o lpi=6'
alias lpi='/usr/bin/lp -o fitplot'
alias emacs='emacs -nw'
alias xterm='xterm -fg white -bg black'
alias w3mg='w3m http://www.google.com'
alias w3mh='w3m http://www.physics.drexel.edu/~wking/'
#alias calendar='calendar -A28'
alias acroread='acroread -geometry 1270x950'
alias graph='graph -TX -C'
alias snownews='snownews -u'
alias oggr='ogg123 -qb 500' # play ogg radio streams (quiet, big input buffer)

# Alias useful one-liners & common commands
alias findex='find . -perm -u+x ! -type d'
alias sortdat='find . -printf "%TY-%Tm-%Td+%TH:%TM:%TS %h/%f\n" | sort -n'
alias sortdirdat='find . -type d -printf "%TY-%Tm-%Td+%TH:%TM:%TS %h/%f\n" | sort -n'
alias sshy='ssh wking@129.25.24.53'
alias ssha='ssh sysadmin@129.25.7.55'
alias sshxa='ssh -X sysadmin@129.25.7.55'

# enable color support of ls and also add handy aliases
if [ "$TERM" != "dumb" ] && [ -x /usr/bin/dircolors ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
    #alias dir='ls --color=auto --format=vertical'
    #alias vdir='ls --color=auto --format=long'

    alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
