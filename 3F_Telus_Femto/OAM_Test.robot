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
    # OAM CLI 진입
    Write    idm oam
    # OAM 내부는 보통 '>' 계열 프롬프트이므로, 둘 다 수용
    Set Client Configuration    prompt=(?m)[#>]\s*$
    ${_}=    Read Until Prompt    # 배너/첫 프롬프트 소거

    # status 실행 및 출력 수집
    Write    status
    ${output}=    Read Until Prompt
    Log    ${output}

    # 배너가 아니라 'status' 결과에서 검증
    Should Contain         ${output}    TUL-LTEAO
    Should Match Regexp    ${output}    (?m)^\s*Started:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*StackRunning:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Availability:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*OpState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*AdminState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*RFTxStatus:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Number of Active MMEs:\s*1\b
   
