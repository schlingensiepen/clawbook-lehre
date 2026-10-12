# shellcheck shell=sh
# clawbook-lehre: exports the keys from ~/.clawbook/secrets (written by
# "clawbook agenten schluessel <NAME>", KEY=VALUE per line) into the shell,
# so that agents and their MCP servers find them as environment variables.
#
# Read by login shells (/etc/profile.d), by bash through a line at the top
# of /etc/bash.bashrc (interactive shells such as VS Code terminals and tmux
# windows, and "ssh clawbook <cmd>", where bash reads that file) and by every
# other bash through BASH_ENV (set in the image and in /etc/environment:
# docker/wslc exec, scripts). POSIX sh, no eval; prints nothing. Only a file that
# belongs to the caller is read (root never reads the student's keys).
# shellcheck disable=SC3067 # test -O: dash and bash, the shells reading this, have it
if [ -n "${HOME:-}" ] && [ -f "${HOME}/.clawbook/secrets" ] \
   && [ -O "${HOME}/.clawbook/secrets" ] && [ -r "${HOME}/.clawbook/secrets" ]; then
  while IFS= read -r _clawbook_line || [ -n "${_clawbook_line}" ]; do
    case ${_clawbook_line} in
      ''|'#'*) ;;
      *=?*)
        _clawbook_name=${_clawbook_line%%=*}
        case ${_clawbook_name} in
          ''|[0-9]*|*[!A-Za-z0-9_]*) ;;
          *) export "${_clawbook_name}=${_clawbook_line#*=}" ;;
        esac
        ;;
    esac
  done < "${HOME}/.clawbook/secrets"
  unset _clawbook_line _clawbook_name
fi
