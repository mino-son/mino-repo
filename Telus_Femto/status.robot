*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    15s
${PROMPT_RE}  [#$]\s*$     # 사용자($)/루트(#) 프롬프트 매칭

*** Test Cases ***
SSH Then Run Commands
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}

    # 초기 프롬프트까지 읽어 비워두기
    Read Until Regexp  ${PROMPT_RE}    timeout=${TIMEOUT}

    # su 승격
    Write              su -
    Read Until Regexp  (?i)password:   timeout=${TIMEOUT}
    Write              ${ROOT_PASS}
    Read Until Regexp  ${PROMPT_RE}    timeout=${TIMEOUT}

    # 명령 실행
    Write              idm oam
    Read Until Regexp  ${PROMPT_RE}    timeout=${TIMEOUT}

    Write              status
    Read Until Regexp  ${PROMPT_RE}    timeout=${TIMEOUT}

    Close All Connections
