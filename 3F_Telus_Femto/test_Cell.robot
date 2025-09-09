*** Settings ***    ##################################################
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
Library                Browser


*** Variables ***    ##################################################
${PROMPT_ANY}                       REGEXP:[#$] ?$
${cell_ssh_connection_ip}           172.30.100.120
${DruidCore_ssh_connection_ip}      10.253.3.107
${segw_ssh_connection_ip}           10.253.3.66
${remote_working_path}              /tmp
${user_id}                          tultefc
${user_pass}                        *eksvkxQkd#!
${root_pass}                        *Tkfrnrtn#!


*** Keywords ***    ##################################################
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
	Sleep    300s
    Close all connections
	Open Connection And Log In LTE    

*** Test Cases ***    ##################################################

# Start Automation Test_initial Cell Settings
#     Cell Reboot And Reconnect
    
#     Write    idm oam -x status
#     ${output_status}=    Read Until Prompt  strip_prompt=True 
#     log     ${output_status}
#     Should Contain    ${output_status}    StackRunning: 1
#     Should Contain    ${output_status}    RFTxStatus: 1
#     Should Contain    ${output_status}    Number of Active MMEs: 1
#     Close all connections  


LTE Check ToD Sync Within 60s (KST)
    Open Connection And Log In LTE

    # 1) 시간 출력 (따옴표 OK, 네 장비 기준)
    Write    TZ=Asia/Seoul date '+%Y-%m-%d %H:%M:%S'
    ${buf}=    Read Until Prompt    strip_prompt=True
    Log    RAW_FROM_DEVICE:\n${buf}

    # 2) (옵션) ANSI 색상/제어코드 제거
    ${buf}=    Replace String Using Regexp    ${buf}    \x1B\[[0-9;]*[A-Za-z]    ${EMPTY}

    # 3) '#'(프롬프트/에코)로 시작하는 줄은 제외하고, 시간 줄만 추출
    #    - 캡처 괄호 없음 → ${matches[0]} 가 순수 문자열
    ${matches}=    Get Regexp Matches    ${buf}    (?m)^(?!#)\s*\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s*$
    Should Not Be Empty    ${matches}
    ${lte_full}=    Strip String    ${matches[0]}
    Log    lte_full=${lte_full}

    # 4) 로컬(KST) 시각과 비교
    ${robot_full}=    Get Current Date    tz=Asia/Seoul    result_format=%Y-%m-%d %H:%M:%S
    Log    robot_full=${robot_full}

    ${lte_epoch}=      Convert Date    ${lte_full}      result_format=epoch    date_format=%Y-%m-%d %H:%M:%S    tz=Asia/Seoul
    ${robot_epoch}=    Convert Date    ${robot_full}    result_format=epoch    date_format=%Y-%m-%d %H:%M:%S    tz=Asia/Seoul
    ${delta}=          Evaluate    abs(${lte_epoch} - ${robot_epoch})
    Log    delta_seconds=${delta}

    Should Be True    ${delta} <= 60

Check Cell Status In CLI
    Open Connection And Log In LTE 
    
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt  strip_prompt=True
    log     ${output_status}
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections
    

# Sync Source NTP status
#     Open Connection And Log In LTE

#     Keepalive Loop Interval  20  60 s     
#     Write    idm oam -x syncmgrstate
#     ${output_ntp_sync}=    Read Until Prompt  strip_prompt=True  
#     log     ${output_ntp_sync}
#     Should Contain    ${output_ntp_sync}    NTP Sync State
#     Should Contain    ${output_ntp_sync}    LOCKED
#     Close all connections


# IPSEC Down
#     Open Connection SecGW Core

#     Write   iptables -A OUTPUT -s ${cell_ssh_connection_ip} -j DROP
#     Write   iptables -A INPUT -s ${cell_ssh_connection_ip} -j DROP
#     ${block_ip}=    Read Until Prompt  strip_prompt=True    
#     Log     ${block_ip}
#     Close all connections
#     Sleep  5s

#     Open Connection And Log In LTE        
#     Keepalive Loop Interval  12  60 s 
    
#     Write    idm oam -x status
#     ${output_mme_status}=    Read Until Prompt  strip_prompt=True   
#     Log      ${output_mme_status}
#     Should Contain    ${output_mme_status}     Virtual IP: down

#     Write    idm oam -x alarm
#     ${output_alarm_status}=    Read Until Prompt  strip_prompt=True   
#     Log      ${output_alarm_status}
#     Should Contain    ${output_mme_status}     IPsec
#     Close all connections
    

# IPSEC Up & Cell up Checking 
#     Open Connection SecGW Core   
    
#     Write   iptables -D INPUT 1
#     Write   iptables -D OUTPUT 1
#     Keepalive Loop Interval  2  60 s
#     Close all connections

#     Open Connection And Log In LTE
    
#     Write    idm oam -x status
#     ${output_status}=    Read Until Prompt  
#     log     ${output_status}
#     Should Contain    ${output_status}    StackRunning: 1
#     Should Contain    ${output_status}    RFTxStatus: 1
#     Should Contain    ${output_status}    Number of Active MMEs: 1
#     Close all connections  