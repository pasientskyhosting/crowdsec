#!/usr/bin/env bats
# vim: ft=bats:list:ts=8:sts=4:sw=4:et:ai:si:

set -u

load "${TEST_DIR}/lib/bats-support/load.bash"
load "${TEST_DIR}/lib/bats-assert/load.bash"

FILE="$(basename "${BATS_TEST_FILENAME}" .bats):"

#declare stderr
CSCLI="${BIN_DIR}/cscli"

setup_file() {
    #shellcheck source=../lib/assert-crowdsec-not-running.sh
    . "${TEST_DIR}/lib/assert-crowdsec-not-running.sh"
    "${TEST_DIR}/instance-data" load
    echo $output >&3
    assert_success
    yq '
        .url="http://localhost:9999" |
        .group_wait="5s" |
        .group_threshold=2
    ' -i "${CONFIG_DIR}/notifications/http.yaml"
    yq '
        .notifications=["http_default"]
    ' -i "${CONFIG_DIR}/profiles.yaml"
    yq '
        .plugin_config.user="" |
        .plugin_config.group=""
    ' -i "${CONFIG_DIR}/config.yaml"
    "${TEST_DIR}/instance-mock-http" start 9999
    "${TEST_DIR}/instance-crowdsec" start
}

teardown_file() {
    "${TEST_DIR}/instance-mock-http" stop
    "${TEST_DIR}/instance-crowdsec" stop
}

setup() {
    "${CSCLI}" decisions delete --all
}

#----------

@test "$FILE add two bans" {
    sleep 5
    run "${CSCLI}" decisions add --ip 1.2.3.4 --duration 30s
    assert_success
    assert_output --partial 'Decision successfully added'

    run "${CSCLI}" decisions add --ip 1.2.3.5 --duration 30s
    assert_success
    assert_output --partial 'Decision successfully added'
    sleep 10
}




#    cat mock_http_server_logs.log
#    log_line_count=$(cat mock_http_server_logs.log | wc -l)
#    if [[ $log_line_count -ne "1" ]] ; then
#        cleanup_tests
#        fail "expected 1 log line from http server"
#    fi
#
#    total_alerts=$(cat mock_http_server_logs.log   | jq  .request_body | jq length)
#    if [[ $total_alerts -ne "2" ]] ; then
#        cleanup_tests
#        fail "expected to receive 2 alerts in the request body from plugin"
#    fi
#
#    first_received_ip=$(cat mock_http_server_logs.log  | jq -r .request_body[0].decisions[0].value)
#    if [[ $first_received_ip != "1.2.3.4" ]] ; then
#        cleanup_tests
#        fail "expected to receive IP 1.2.3.4 as value of first decision"
#    fi
#
#    second_received_ip=$(cat mock_http_server_logs.log  | jq -r .request_body[1].decisions[0].value)
#    if [[ $second_received_ip != "1.2.3.5" ]] ; then
#        cleanup_tests
#        fail "expected to receive IP 1.2.3.5 as value of second decision"
#    fi
#}
#
#setup_tests
#run_tests
#cleanup_tests
#





# XXX not doing this
#    cat ./config/config.yaml | sed 's/group: nogroup/group: '$(groups nobody | cut -d ':' -f2 | tr -d ' ')'/' | sudo tee /etc/crowdsec/config.yaml > /dev/null

