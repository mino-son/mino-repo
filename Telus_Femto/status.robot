*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    15s
${PROMPT_RE}  [#$]\s*$

*** Test Cases ***
SSH Then Run Commands
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}
    Open Shell
    Read Until Regexp  ${PROMPT_RE}

    Write              su -
    Read Until Regexp  (?i)password:
    Write              ${ROOT_PASS}
    Read Until Regexp  ${PROMPT_RE}

    Write              idm oam
    Read Until Regexp  ${PROMPT_RE}

    Write              status
    Read Until Regexp  ${PROMPT_RE}

    Close All Connections
