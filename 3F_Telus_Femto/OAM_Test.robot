*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
#Suite Setup            Open Connection And Log In
Test Teardown         SSHLibrary.Close all connections

*** Variables ***
${cell_ssh_connection_ip}   172.30.100.120
${pkg_lte_name}             ifq-LGU-LTEAO-4.4.1-rc0.tar.gz
${remote_working_path}      /tmp
${user_id}                  tultefc
${user_pass}                *eksvkxQkd#!
${root_pass}                *Tkfrnrtn#!


*** Keywords ***
Open Connection And Log In LTE
    SSHLibrary.Open Connection    ${cell_ssh_connection_ip}
    SSHLibrary.Login    ${user_id}    ${user_pass}
    Write    su -
    Read Until Regexp    (?i)password:
    Write    ${root_pass}
    # BusyBox 배너 포함, 루트 프롬프트(#) 등장까지 대기
    ${_}=    Read Until Regexp    (?s)\n#\s*$
    # 이후 기본 프롬프트/타임아웃 설정 (세션 전체에 적용)
    Set Client Configuration    prompt=(?m)^#\s*$    timeout=30 seconds
    Read Until Prompt    # 버퍼 잔여 제거

Check ps Utility
    ${ps_output}=    Execute Command    ps
    Should Contain    ${ps_output}    ps

Check ls Utility
    ${ls_output}=    Execute Command    ls

*** Test Cases ***

#Cell Reboot And Reconnect
#   Open Connection And Log In LTE
#	Write    reboot
#	Sleep  300s
#   Close all connections
#	Open Connection And Log In LTE

Check OAM Status In CLI (Robust)
    Open Connection And Log In LTE
    # 1) OAM 진입
    Write    idm oam
    # OAM 프롬프트 라인 등장까지 대기 (예: "OAM TUL-LTEAO-5.3.5 />")
    ${_}=    Read Until Regexp    (?m)^OAM .*?/>\s*$
    # OAM 내부 프롬프트로 교체
    Set Client Configuration    prompt=(?m)^OAM .*?/>\s*$
    Read Until Prompt

    # 2) status 실행
    Write    status
    ${output}=    Read Until Prompt
    Log    ${output}

    # 3) 검증
    Should Contain         ${output}    TUL-LTEAO
    Should Match Regexp    ${output}    (?m)^\s*Started:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*StackRunning:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Availability:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*OpState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*AdminState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*RFTxStatus:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Number of Active MMEs:\s*1\b