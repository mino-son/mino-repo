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

Check OAM Status In CLI (Robust)
    # 0) Connection SSH
    Open Connection And Log In LTE
    # 1) OAM 진입
    Write    idm oam
    # 배너/프롬프트 ANSI 섞여도 "TUL-LTEAO ... />" 조각이 보일 때까지만 동기화
    ${_}=    Read Until Regexp    (?s)TUL-LTEAO.*?/>    timeout=20 seconds

    # 2) status 실행
    Write    status
    # status의 "마지막 줄"로 간주할 지표까지 대기 (프롬프트에 의존 X)
    ${output}=    Read Until Regexp    (?m)^\\s*Number of Active MMEs:\\s*\\d+\\b    timeout=30 seconds
    Log    ${output}

    # 3) 검증
    Should Contain         ${output}    TUL-LTEAO
    Should Match Regexp    ${output}    (?m)^\\s*Started:\\s*1\\b
    Should Match Regexp    ${output}    (?m)^\\s*StackRunning:\\s*1\\b
    Should Match Regexp    ${output}    (?m)^\\s*Availability:\\s*1\\b
    Should Match Regexp    ${output}    (?m)^\\s*OpState:\\s*1\\b
    Should Match Regexp    ${output}    (?m)^\\s*AdminState:\\s*1\\b
    Should Match Regexp    ${output}    (?m)^\\s*RFTxStatus:\\s*1\\b
    Should Match Regexp    ${output}    (?m)^\\s*Number of Active MMEs:\\s*1\\b

   
