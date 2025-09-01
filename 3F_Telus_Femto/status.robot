*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    30s

*** Test Cases ***
SSH Then Run Commands (with sleep)
    # 1) SSH 로그인 & 기본 읽기 타임아웃 설정
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}
    Set Client Configuration    timeout=${TIMEOUT}
    Sleep              3s

    # 로그인 동기화
    Write              echo __READY__
    Read Until         __READY__

    # 2) su 전환
    Write              su -
    Read Until         assword:
    Write              ${ROOT_PASS}
    Sleep              3s
    Write              echo __ROOT__
    Read Until         __ROOT__

    # 3) 명령 실행
    Write              idm oam; echo __DONE1__
    Read Until         __DONE1__

    Write              status; echo __DONE2__
    Read Until         __DONE2__

    Close All Connections
