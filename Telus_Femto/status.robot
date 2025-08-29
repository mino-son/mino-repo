*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    30s
# 프롬프트: 줄 끝의 # 또는 $ (공백 허용). \s 는 이스케이프 보존 위해 \\s 사용 권장
${PROMPT_RE}  (?m)[#$]\\s*$

*** Test Cases ***
SSH Then Run Commands
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}

    # 로그인 배너 비우고 첫 프롬프트 대기
    Read Until Regexp  ${PROMPT_RE}    timeout=${TIMEOUT}

    # 루트 승격
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
