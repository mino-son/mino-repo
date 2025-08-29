*** Settings ***
Library    SSHLibrary
Library    String    # 문자열 검색/비교 편하게 쓰기 위해 추가

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    30s

*** Test Cases ***
SSH Then Run Commands (with validation)
    # 1) SSH 로그인
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}
    Set Client Configuration    timeout=${TIMEOUT}
    Sleep              3s

    Write              echo __READY__
    Read Until         __READY__

    # 2) su 전환
    Write              su -
    Read Until         assword:
    Write              ${ROOT_PASS}
    Sleep              3s
    Write              echo __ROOT__
    Read Until         __ROOT__

    # 3) status 실행 (출력 캡처)
    Write              status
    ${output}=         Read Until    OAM TUL-LTEAO-5.3.5 />    ${TIMEOUT}
    Log To Console     ${output}

    # 4) PASS/FAIL 조건 확인
    Should Contain     ${output}    Started: 1
    Should Contain     ${output}    StackRunning: 1
    Should Contain     ${output}    Availability: 1
    Should Contain     ${output}    OpState: 1
    Should Contain     ${output}    AdminState: 1
    Should Contain     ${output}    RFTxStatus: 1
    Should Contain     ${output}    Number of Active MMEs: 1

    Close All Connections
