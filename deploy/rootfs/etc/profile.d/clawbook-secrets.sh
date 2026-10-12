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
        # Names that would change the shell or every program are skipped
        # (same list as SECRET_REFUSED_* in /usr/local/bin/clawbook).
        case ${_clawbook_name} in
          ''|[0-9]*|*[!A-Za-z0-9_]*) ;;
          LD_*|BASH_*|PYTHON*|NODE_*|XDG_*|LC_*|SSH_*) ;;
          PATH|HOME|SHELL|IFS|ENV|PROMPT_COMMAND|USER|LOGNAME|PWD|OLDPWD|TMPDIR) ;;
          TERM|DISPLAY|LANG|PS1|PS2|PS4|CDPATH|GLOBIGNORE|SHELLOPTS) ;;
          ANTHROPIC_API_KEY|ANTHROPIC_AUTH_TOKEN|ANTHROPIC_BASE_URL|CLAUDE_CODE_OAUTH_TOKEN) ;;
          OPENAI_API_KEY|OPENAI_BASE_URL|CODEX_API_KEY|GEMINI_API_KEY|GOOGLE_API_KEY) ;;
          GOOGLE_APPLICATION_CREDENTIALS|GH_TOKEN|GITHUB_TOKEN|COPILOT_GITHUB_TOKEN) ;;
          GH_ENTERPRISE_TOKEN|*_PROXY|*_proxy) ;;
          *) export "${_clawbook_name}=${_clawbook_line#*=}" ;;
        esac
        ;;
    esac
  done < "${HOME}/.clawbook/secrets"
  unset _clawbook_line _clawbook_name
fi
