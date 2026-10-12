# shellcheck shell=sh
# clawbook-lehre: opens the clawbook menu once when someone logs in
# interactively via SSH (ssh clawbook). Sourced by /etc/profile, i.e. only
# for login shells; POSIX sh on purpose (dash reads it as well).
#
# Not started: "ssh clawbook <command>", scp/sftp (no login shell, no
# terminal), VS Code terminals, tmux windows, docker/wslc exec without SSH
# (no SSH_TTY), a second login shell in the same session, and never when
# the student switched it off (~/.clawbook/menue-beim-login-aus).
if [ -n "${SSH_TTY:-}" ] && [ -z "${TMUX:-}" ] && [ -z "${CLAWBOOK_MENU_SHOWN:-}" ] \
   && [ "${TERM_PROGRAM:-}" != vscode ] && [ -t 0 ] && [ -t 1 ] \
   && command -v clawbook >/dev/null 2>&1; then
  case $- in
    *i*)
      if ! env | grep -q '^VSCODE_'; then
        CLAWBOOK_MENU_SHOWN=1
        export CLAWBOOK_MENU_SHOWN
        if [ -e "${HOME}/.clawbook/menue-beim-login-aus" ]; then
          echo "Das clawbook-Menü öffnest du mit: clawbook"
        else
          clawbook
          echo "Das clawbook-Menü öffnest du jederzeit wieder mit: clawbook"
        fi
      fi
      ;;
  esac
fi
