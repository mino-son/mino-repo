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
    SSHLibrary.Login    ${user_id}        ${user_pass}
    Write   su -
    Read Until Regexp    Password:
    Write   ${root_pass}
    Set Client Configuration    prompt=#

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

Check OAM Status In CLI
    Open Connection And Log In LTE
    # OAM 진입
    Write    idm oam
    # OAM 내부 프롬프트는 '/>' 뒤로 ANSI/문자 조금 더 붙음 → 느슨하게 매칭
    Set Client Configuration    prompt=/>.*$    timeout=15 seconds
    ${_}=    Read Until Prompt     # 배너/첫 프롬프트 소거

    # status 실행 및 출력 수집
    Write    status
    ${output}=    Read Until Prompt
    Log    ${output}

    Should Contain         ${output}    TUL-LTEAO
    Should Match Regexp    ${output}    (?m)^\s*Started:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*StackRunning:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Availability:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*OpState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*AdminState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*RFTxStatus:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Number of Active MMEs:\s*1\b

   
