*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}          172.30.100.120
${USER}          tultefc
${PASS}          *eksvkxQkd#!
${ROOT_PASS}     *Tkfrnrtn#!
${PORT}          22
${TIMEOUT}       15s
${PROMPT_RE}     [#$]\s*$          # 사용자/루트 공통 프롬프트 정규식(필요하면 수정)

*** Test Cases ***
SSH Then Run Commands (with su)
    # 1) SSH 접속
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}

    # 인터랙티브 셸 열고 최초 프롬프트까지 비움
    Open Shell
    Read Until Regexp  ${PROMPT_RE}    timeout=${TIMEOUT}

    # 2) su로 루트 승격 (비번 입력)
    Write              su -
    Read Until Regexp  (?i)password:    timeout=${TIMEOUT}
    Write              ${ROOT_PASS}
    Read Until Regexp  ${PROMPT_RE}     timeout=${TIMEOUT}

    Sleep              3s

    # 3) idm oam 실행 → 종료코드 확인
    Write              idm oam
    ${out1}=           Read Until Regexp   ${PROMPT_RE}    timeout=${TIMEOUT}
    Log                ${out1}
    ${rc1}=            Get Last RC From Shell
    Should Be Equal As Integers    ${rc1}    0

    Sleep              3s

    # 4) status 실행 → 종료코드 확인
    Write              status
    ${out2}=           Read Until Regexp   ${PROMPT_RE}    timeout=${TIMEOUT}
    Log                ${out2}
    ${rc2}=            Get Last RC From Shell
    Should Be Equal As Integers    ${rc2}    0

    Close All Connections


*** Keywords ***
Get Last RC From Shell
    [Documentation]  직전 명령의 종료코드($?)를 읽어 0/비0 판정용으로 반환
    Write              echo __RC:$?
    ${rcout}=          Read Until Regexp    ${PROMPT_RE}    timeout=${TIMEOUT}
    # rcout 예: "__RC:0" ... 프롬프트 전까지 포함됨
    ${match}=          Evaluate    __import__('re').search(r'__RC:(\d+)', """${rcout}""")
    Run Keyword If     '${match}'=='None'    Fail    Could not read return code from shell output:\n${rcout}
    ${code}=           Evaluate    int(${match}.group(1))
    [Return]           ${code}
