*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
Library                Browser


*** Variables ***
${PROMPT_ANY}                       REGEXP:[#$] ?$
${cell_ssh_connection_ip}           172.30.100.120
${DruidCore_ssh_connection_ip}      10.253.3.107
${segw_ssh_connection_ip}           10.253.3.66
${remote_working_path}              /tmp
${user_id}                          tultefc
${user_pass}                        *eksvkxQkd#!
${root_pass}                        *Tkfrnrtn#!


*** Keywords ***
Keepalive Loop Interval
    [Arguments]    ${loops}=14    ${interval}=60 s    ${marker}=__KA__
    FOR    ${i}    IN RANGE    ${loops}
        Write    echo ${marker}
        Read Until Prompt    strip_prompt=True
        Sleep    ${interval}
    END

Check ps Utility
    ${ps_output}=    Execute Command    ps
    Should Contain    ${ps_output}    ps

Check ls Utility
    ${ls_output}=    Execute Command    ls

Open Connection And Log In LTE
    SSHLibrary.Open Connection    ${cell_ssh_connection_ip}    
    SSHLibrary.Login              ${user_id}    ${user_pass}
    Write    su -
    Read Until Regexp    (?i)password:
    Write    ${root_pass}
    Set Client Configuration    prompt=#    
    # ✅ 방어적 플러시: 이전 잔여 출력(배너 등) 확실히 제거
    Read Until Prompt             strip_prompt=True

Open Connection SSH Druid Core
    SSHLibrary.Open Connection    ${DruidCore_ssh_connection_ip}
    SSHLibrary.Login    root    qucell12345
    Set Client Configuration    prompt=#
    # ✅ 방어적 플러시: 이전 잔여 출력(배너 등) 확실히 제거
    Read Until Prompt             strip_prompt=True

Open Connection SecGW Core
    SSHLibrary.Open Connection    ${segw_ssh_connection_ip}
    SSHLibrary.Login    secgw    qucell12345
    Write    su -
    Read Until Regexp    (?i)password:
    Write    qucell12345
    Set Client Configuration    prompt=#
    # ✅ 방어적 플러시: 이전 잔여 출력(배너 등) 확실히 제거
    Read Until Prompt             strip_prompt=True

Cell Reboot And Reconnect
    Open Connection And Log In LTE
	Write    reboot
	Sleep  200s
    Close all connections
	Open Connection And Log In LTE    
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt  strip_prompt=True 
    log     ${output_status}
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections  

*** Test Cases ***

Start Automation Test
    Cell Reboot And Reconnect
    Open Connection And Log In LTE
    Keepalive Loop Interval     10   60 s
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt  strip_prompt=True 
    log     ${output_status}
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections  
    

Check Cell Status In CLI
    Open Connection And Log In LTE 
    
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt  strip_prompt=True
    log     ${output_status}
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections
    

Sync Source NTP status
    Open Connection And Log In LTE

    Keepalive Loop Interval  20  60 s     
    Write    idm oam -x syncmgrstate
    ${output_ntp_sync}=    Read Until Prompt  strip_prompt=True  
    log     ${output_ntp_sync}
    Should Contain    ${output_ntp_sync}    NTP Sync State
    Should Contain    ${output_ntp_sync}    LOCKED
    Close all connections


IPSEC Down
    Open Connection SecGW Core

    Write   iptables -A OUTPUT -s ${cell_ssh_connection_ip} -j DROP
    Write   iptables -A INPUT -s ${cell_ssh_connection_ip} -j DROP
    ${block_ip}=    Read Until Prompt  strip_prompt=True    
    Log     ${block_ip}
    Close all connections
    Sleep  5s

    Open Connection And Log In LTE        
    Keepalive Loop Interval  12  60 s 
    
    Write    idm oam -x status
    ${output_mme_status}=    Read Until Prompt  strip_prompt=True   
    Log      ${output_mme_status}
    Should Contain    ${output_mme_status}     Virtual IP: down
    Close all connections
    

IPSEC Up & Cell up Checking 
    Open Connection SecGW Core   
    
    Write   iptables -D INPUT 1
    Write   iptables -D OUTPUT 1
    Keepalive Loop Interval  2  60 s
    Close all connections

    Open Connection And Log In LTE
    
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt  
    log     ${output_status}
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections  