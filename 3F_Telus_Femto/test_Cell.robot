*** Settings ***    ##################################################
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
Library                Browser
Library                JSONLibrary
Library                Process
Library                OperatingSystem
Library                Collections
Library                BuiltIn


*** Variables ***    ##################################################
${PROMPT_ANY}                           REGEXP:[#$] ?$
${lte_cell_ssh_connection_ip}           172.30.100.114
${nr_cell_ssh_connection_ip}            172.30.100.110
${DruidCore_ssh_connection_ip}          10.253.3.107
${segw_ssh_connection_ip}               10.253.3.66
${jenkinsserver_ssh_connection_ip}      10.253.3.186
${lte_qemsapi_connection_ip}            10.253.3.83:11000
${remote_working_path}                  /tmp
${lte_user_id}                          tultepc
${lte_user_pass}                        *Rhkqorl#!
${lte_root_pass}                        *EhEldi#!
${device_serial}                        441CA25X000019
${nr_user_id}                           tunrpcs
${nr_user_pass}                         *Qkdpdi#!
${nr_root_pass}                         *Rhcrpxkd#!
${REMOTE_PATH}                          /tmp/config.xml
${LOCAL_DIR}          ${OUTPUT DIR}/artifacts
${LOCAL_PATH}         ${LOCAL_DIR}/config.xml

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
    SSHLibrary.Open Connection    ${lte_cell_ssh_connection_ip}
    SSHLibrary.Login              ${lte_user_id}    ${lte_user_pass}
    Write    su -
    Read Until Regexp    (?i)password:
    Write    ${lte_root_pass}

    Set Client Configuration    prompt=#
    # ✅ 방어적 플러시: 이전 잔여 출력(배너 등) 확실히 제거
    Read Until Prompt             strip_prompt=True

Open Connection And Log In NR
    SSHLibrary.Open Connection    ${nr_cell_ssh_connection_ip}
    SSHLibrary.Login              ${nr_user_id}    ${nr_user_pass}
    Write    su -
    Read Until Regexp    (?i)password:
    Write    ${nr_root_pass}

    Set Client Configuration      prompt=# 
    Read Until Prompt             strip_prompt=True


    #Set Client Configuration    prompt=REGEXP:root@localhost:[^\\n]*#\\s*$
    #Read Until Prompt    strip_prompt=True

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
#    Set Client Configuration    prompt=#
#    # ✅ 방어적 플러시: 이전 잔여 출력(배너 등) 확실히 제거
#    Read Until Prompt             strip_prompt=True
    Set Client Configuration      prompt=REGEXP:(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*[#$] ?(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*\\s*$
    Read Until Prompt    strip_prompt=True
    
Open Connection Jenkins Server
    SSHLibrary.Open Connection    ${jenkinsserver_ssh_connection_ip}
    SSHLibrary.Login    epc2    qucell
    Write    su -
    Read Until Regexp    (?i)password:
    Write    qucell
    #Set Client Configuration    prompt=#
    # ✅ 방어적 플러시: 이전 잔여 출력(배너 등) 확실히 제거
    #Read Until Prompt             strip_prompt=True
    Set Client Configuration      prompt=REGEXP:(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*[#$] ?(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*\\s*$
    Read Until Prompt    strip_prompt=True
    


Cell Reboot And Reconnect
    Open Connection And Log In LTE
	Write    reboot
	Sleep    300s
    Close all connections
	Open Connection And Log In LTE


ToD Status
    [Arguments]    ${text}
    # "- Status = Synchronized" 줄에서 값만 뽑아옴
    ${m}=    Get Regexp Matches    ${text}    (?m)^-\s*Status\s*=\s*([^\r\n]+)
    Should Not Be Empty    ${m}
    [Return]    ${m[0]}

Check LTE Cell Status In CLI
    Open Connection And Log In LTE

    Write    idm oam -x status
    ${output_status}=    Read Until Prompt  strip_prompt=True
    log     ${output_status}
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections

Check NR Cell Status In CLI
    Open Connection And Log In NR

    Write    nrctl
    ${output_status}=    Read Until Prompt  strip_prompt=True
    log     ${output_status}
    Should Contain    ${output_status}    cellState: Active
    Close all connections

*** Test Cases ***    ##################################################

#LTE initial Cell Settings        #정상동작 확인
#     Cell Reboot And Reconnect
#     Keepalive Loop Interval  5  60 s
#     Write    idm oam -x status
#     ${output_status}=    Read Until Prompt  strip_prompt=True
#     log     ${output_status}
#     Should Contain    ${output_status}    StackRunning: 1
#     Should Contain    ${output_status}    RFTxStatus: 1
#     Should Contain    ${output_status}    Number of Active MMEs: 1
#     Close all connections


LTE Check ToD Sync         #정상동작 확인
    [Documentation]    ToD Synchronized 정상 동작 확인
    ...                idm oam -x ls Device.Time 출력 결과 중, Status = Synchronized 를 확인
    [Tags]    LTE PnP
    ...       LTE Sanity
    Open Connection And Log In LTE
    Write    date +%s
    ${buf}=    Read Until Prompt    strip_prompt=True
    ${m}=      Get Regexp Matches    ${buf}    \\d{10,}
    Should Not Be Empty    ${m}
    ${lte_epoch}=    Convert To Integer    ${m[0]}
    ${robot_epoch}=  Get Current Date    result_format=epoch
    ${delta}=        Evaluate    abs(${lte_epoch} - ${robot_epoch})
    Should Be True   ${delta} <= 60

    Write    idm oam -x ls Device.Time
    ${output_device_time}=    Read Until Prompt  strip_prompt=True
    log     ${output_device_time}
    Should Contain    ${output_device_time}    Status = Synchronized
    ## clean_output을 이용해 개행문자 제외
    ${clean_output}=    Replace String Using Regexp    ${output_device_time}    (\\x1B\\[[0-9;]*[A-Za-z]|\\[[0-9;]*m)    ${EMPTY}

    Set Test Message   ToD=${clean_output}
    Set Test Message   ToD=${delta}        #추가했음, 문제시 삭제

    Close all connections

LTE Check IPSEC Tunnel complete        #정상동작 확인
    [Documentation]    IPSec Connected 확인
    ...                idm oam -x status 의 결과 중, "Virtual IP: up" 체크
    [Tags]    LTE PnP
    ...       LTE Sanity
    Open Connection And Log In LTE
    # Write    ipsec statusall
    # ${lte_ipsec_statusall}=    Read Until Prompt    strip_prompt=True
    # ## clean_output을 이용해 개행문자 제외
    # ${clean_output}=    Replace String Using Regexp    ${lte_ipsec_statusall}    (\\x1B\\[[0-9;]*[A-Za-z]|\\[[0-9;]*m)    ${EMPTY}
    # Should Contain    ${clean_output}    172.21.0.3
    # Should Contain    ${clean_output}    Security Associations (
    Write    idm oam -x status
    ${lte_status}=    Read Until Prompt    strip_prompt=True
    ${clean2_output}=    Replace String Using Regexp    ${lte_status}    (\\x1B\\[[0-9;]*[A-Za-z]|\\[[0-9;]*m)    ${EMPTY}
    Should Contain    ${clean2_output}    Virtual IP: up
    Set Test Message   ipsec status=${clean2_output}

    Close all connections


LTE Check QEMS Connected            #정상동작 확인
    [Documentation]    QEMS 와 LTE Cell Conneted status 확인
    ...                QEMS API Get으로, QEMS Connected Device(serialNumber)의 "Status":"ServiceOn" 조회
    [Tags]    LTE PnP
    ...       LTE Sanity
        
    Open Connection Jenkins Server

    # 1) ‘그대로’ 한 문자열로 만든다 (명령 내용 절대 변경 없음)
    ${cmd}=    Catenate    SEPARATOR=${SPACE}    curl -v -X 'POST' http://10.253.3.83:11000/api/v1/telus    -H 'accept: application/json'    -H 'Authorization: Basic dGVsdXM6VGVsdXMyNDA5IQ=='    -H 'Content-Type: application/json; charset=utf-8'    -d '{"actionType":"SN_GetStatusLTE","serialNumber":["441CA25X000019"]}'

    # 2) 대화형 Write 대신, 단발 실행으로 stdout/stderr/rc 모두 받기
    ${out}    ${err}    ${rc}=    Execute Command    ${cmd}    return_stdout=True    return_stderr=True    return_rc=True    timeout=60s
    Should Contain    ${out}    "Status":"ServiceOn"
    Should Contain    ${out}    441CA25X000019
    Set Test Message       QEMS status=${out}

    Close All Connections
   

# LTE Sync Source NTP status
#     Open Connection And Log In LTE

#     Keepalive Loop Interval  20  60 s
#     Write    idm oam -x syncmgrstate
#     ${output_ntp_sync}=    Read Until Prompt  strip_prompt=True
#     log     ${output_ntp_sync}
#     Should Contain    ${output_ntp_sync}    NTP Sync State
#     Should Contain    ${output_ntp_sync}    LOCKED
#     Close all connections

LTE Sync Source EXT_PPS status
    [Documentation]    synchronization (EXTPPS) 동작 확인 (LTE Cell Sync)
    ...                idm oam -x syncmgrstate 입력 시, [Active Sync Source : EXTPPS], [Sync Manager State : DISP] 출력 확인
    [Tags]  LTE Sanity
    ...     LTE PnP
    Open Connection And Log In LTE
    Keepalive Loop Interval  1  5 s         ## 실제 시험시, 시간 변경 필요 (reboot 시간 미고려 되어있음)
    Write    idm oam -x syncmgrstate
    ${output_extpps_sync}=    Read Until Prompt  strip_prompt=True
    log     ${output_extpps_sync}
    Should Contain    ${output_extpps_sync}    Active Sync Source : EXTPPS
    Should Contain    ${output_extpps_sync}    Sync Manager State : DISP
    Set Test Message   LTE Sync EXT_PPS status=${output_extpps_sync}
    Close all connections


# LTE IPSEC Down        #정상동작 확인
#     Open Connection SecGW Core
#     [Documentation]    IPSec (down/up repeat)
#     ...                SecGW 접속 후, LTE Device의 Inner IP (172.30.100.xxx) 를 Block
#     ...                IPSec Down 확인 및 idm oam -x status 입력 시 IPSec 관련 alarm 확인 [Virtual IP: down], [IPSec Tunnel Down]
#     [Tags]      LTE Regression
#     ...         LTE IPsec

#     Write   iptables -A INPUT -s ${lte_cell_ssh_connection_ip} -j DROP
#     Write   iptables -A OUTPUT -s ${lte_cell_ssh_connection_ip} -j DROP
#     ${block_ip}=    Read Until Prompt  strip_prompt=True
#     Log     ${block_ip}
#     Close all connections
#     Sleep  5s

#     Open Connection And Log In LTE
#     Keepalive Loop Interval  13  60 s

#     Write    idm oam -x status
#     ${output_mme_status}=    Read Until Prompt  strip_prompt=True
#     Log      ${output_mme_status}
#     Should Contain    ${output_mme_status}     Virtual IP: down

#     Write    idm oam -x alarm
#     ${output_alarm_status}=    Read Until Prompt  strip_prompt=True
#     Log      ${output_alarm_status}
#     Should Contain    ${output_mme_status}     IPSec Tunnel Down
#     Set Test Message   Cell Alarm after IPSec Down=${output_mme_status}
#     Close all connections


# LTE IPSEC Up & Cell up Checking        #정상동작 확인
#     Open Connection SecGW Core
#     [Documentation]    IPSec (down/up repeat)
#     ...                SecGW 접속 후, LTE Device의 Inner IP (172.30.100.xxx) Block Table 제거
#     ...                IPSec Up 확인 및 idm oam -x status 입력 시 IPSec Up 확인 [StackRunning: 1, RFTxStatus: 1, Number of Active MMEs: 1, AdminState: 1]
#     [Tags]      LTE Regression
#     ...         LTE IPsec

#     Write   iptables -D INPUT -s ${lte_cell_ssh_connection_ip} -j DROP
#     Write   iptables -D OUTPUT -s ${lte_cell_ssh_connection_ip} -j DROP
#     Keepalive Loop Interval  5  60 s
#     Close all connections

#     Open Connection And Log In LTE

#     Write    idm oam -x status
#     ${output_status}=    Read Until Prompt
#     log     ${output_status}
#     Should Contain    ${output_status}    StackRunning: 1
#     Should Contain    ${output_status}    RFTxStatus: 1
#     Should Contain    ${output_status}    Number of Active MMEs: 1
#     Should Contain    ${output_status}    AdminState: 1
#     Set Test Message   Cell Status After IPSec Up =${output_status}
#     Close all connections

# Reboot LTE Pico From QEMS(API)            ##정상동작 확인 필요 - 코드 수정
#     [Documentation]    Reboot system (EMS) - LTE Cell
#     ...                QEMS API으로 LTE Cell Reboot 후, Cell Up statue 확인
#     [Tags]             LTE Regression
#     ...                QEMS

#     Open Connection Jenkins Server
#     Write    curl -v -X 'POST' http://${lte_qemsapi_connection_ip}/api/v1/telus -H 'accept: application/json'  -H 'Authorization: Basic dGVsdXM6VGVsdXMyNDA5IQ=='  -H 'Content-Type: application/json; charset=utf-8'  -d '{"actionType":"RebootLTE","serialNumber":"441CA25X000019"}'
#     Close all connections

#     Sleep    180s
#     Open Connection And Log In LTE
#     Check LTE Cell Status In CLI
#     Set Test Message   Cell Status After IPSec Up =${output_status}
#     Close all connections


#########################################################################################

Check NR Cell Active In CLI
    Open Connection And Log In NR
    [Documentation]    Checking NR Cell Normal Running
    [Tags]   NR status

    Write    nrctl
    ${output_status}=    Read Until Prompt  strip_prompt=True    
    Should Contain    ${output_status}    cellState: Active
    Should Contain    ${output_status}    operationalState: Enabled
    Set Test Message   Cell status=${output_status}
    Close all connections

Debug Chat GPT
    Open Connection And Log In NR
 # 1) 셸 프롬프트(#)로 동기화 + 확인 로그
    Set Client Configuration    timeout=20 seconds
    Set Client Configuration    prompt=REGEXP:[#] ?$
    Write    ${EMPTY}
    ${shell}=    Read Until Prompt    strip_prompt=True
    Log To Console    ===SHELL_PROMPT===\n${shell}\n===END===

# 2) nrctl 진입 → '>' 프롬프트 포착 후, 기대 프롬프트를 '>'로 전환
    Write    nrctl
    ${gt_seen}=    Read Until Regexp    (?m)[>]\\s*$
    Log To Console    ===NRCTL_PROMPT_SEEN===\n${gt_seen}\n===END===
    Set Client Configuration    prompt=REGEXP:(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*[>]\\s*(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*$

# 3) 상태 조회 → 이제는 '>' 기준으로 안정적으로 읽힘
    Write    show status
    ${output_status}=    Read Until Prompt    strip_prompt=True
    Log    ${output_status}
    Should Contain    ${output_status}    cellState: Active
    Should Contain    ${output_status}    operationalState: Enabled
    
    Close all connections

Debug 222
# 0) 디버그 스냅샷: 현재 화면/PS1/TERM 확인 (프롬프트 필요 없음)
    Set Log Level    TRACE
    Write    ${EMPTY}
    Sleep    0.4s
    ${snap}=    Read
    Log To Console    ===SNAP===\n${snap}\n===END===
    Write    printf 'PS1<<%s>> TERM=%s\n' "$PS1" "$TERM"
    Sleep    0.4s
    ${env}=    Read
    Log To Console    ===ENV===\n${env}\n===END===

# 1) 셸 프롬프트 동기화 (ANSI 허용 + #/$ 모두 허용)
    Set Client Configuration    timeout=20 seconds
    Set Client Configuration    prompt=REGEXP:(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*[#$] ?(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*\\s*$
    Write    export TERM=dumb; unset PROMPT_COMMAND
    ${shell}=    Read Until Prompt    strip_prompt=True
    Log To Console    ===SHELL_PROMPT_SYNCED===\n${shell}\n===END===

# 2) nrctl 진입 → '>' 프롬프트로 전환 (ANSI 허용)
    Write    nrctl
    ${gt_seen}=    Read Until Regexp    (?m)(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*[>]\\s*$
    Log To Console    ===NRCTL_PROMPT_SEEN===\n${gt_seen}\n===END===
    Set Client Configuration    prompt=REGEXP:(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*[>]\\s*(?:\\x1B\\[[0-9;]*[ -/]*[@-~])*\\s*$

# 3) 상태 조회 (이제는 '>' 기준으로 안정적으로 읽힘)
    Write    show status
    ${output_status}=    Read Until Prompt    strip_prompt=True
    Log    ${output_status}
    Should Contain    ${output_status}    cellState: Active
    Should Contain    ${output_status}    operationalState: Enabled

    Close all connections

NR Cell ToD Sync complete
    [Documentation]    Checking NR Cell Tod Sync
    [Tags]    NR PnP
    Open Connection And Log In NR
    Write    nrctl
    ${nr_tod_status}=    Read Until Prompt    strip_prompt=True

    Should Contain    ${nr_tod_status}    NTP Status: SYNCHRONIZED
    Set Test Message   ToD status=${nr_tod_status}
    Close all connections

NR Check IPSEC Tunnel complete
    [Documentation]    NR IPSec Connected 확인
    [Tags]    NR PnP
    Open Connection And Log In NR

    Write    swanctl -l
    ${nr_ipsec_status}=    Read Until Prompt    strip_prompt=True
    ${clean_output}=    Replace String Using Regexp    ${nr_ipsec_status}    (\\x1B\\[[0-9;]*[A-Za-z]|\\[[0-9;]*m)    ${EMPTY}
    Should Contain    ${clean_output}    ESTABLISHED
    Should Contain    ${clean_output}    INSTALLED
    Should Contain    ${clean_output}    IPSec Tunnel Down
    Set Test Message   NR IPSec status=${clean_output}

    Close all connections

NR Cell Sync Source complete
    [Documentation]    Checking NR Cell Sync Locked
    [Tags]    NR PnP
    Open Connection And Log In NR
    Write    sysrepocfg -X -mo-ran-sync -doperational
    ${nr_sync_status}=    Read Until Prompt    strip_prompt=True

    Should Contain    ${nr_sync_status}    <sync-state>LOCKED</sync-state>
    Set Test Message   Sync Source status=${nr_sync_status}
    Close all connections
