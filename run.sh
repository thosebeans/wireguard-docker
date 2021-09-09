#!/usr/bin/env sh

#############
# constants #
#############

# REGEX_IP4 matches all valid IPv4 addresses.
REGEX_IP4='
((
((([01]?[0-9]{1,2})|(2[0-4][0-9])|(25[0-5]))\.){3}
(([01]?[0-9]{1,2})|(2[0-4][0-9])|(25[0-5]))
)\/(
([12]?[0-9])|(3[0-2])
))
'

REGEX_IP4="$(echo "$REGEX_IP4" | tr -d '\n')"

# REGEX_IP6 matches all valid IPv6 addresses.
REGEX_IP6='
((
(([0-9a-fA-F]{1,4}\:){7}[0-9a-fA-F]{1,4})|
(\:(\:[0-9a-fA-F]{1,4}){1,7})|
(([0-9a-fA-F]{1,4}\:){1}((\:[0-9a-fA-F]{1,4}){0,6}|\:))|
(([0-9a-fA-F]{1,4}\:){2}((\:[0-9a-fA-F]{1,4}){0,5}|\:))|
(([0-9a-fA-F]{1,4}\:){3}((\:[0-9a-fA-F]{1,4}){0,4}|\:))|
(([0-9a-fA-F]{1,4}\:){4}((\:[0-9a-fA-F]{1,4}){0,3}|\:))|
(([0-9a-fA-F]{1,4}\:){5}((\:[0-9a-fA-F]{1,4}){0,2}|\:))|
(([0-9a-fA-F]{1,4}\:){6}((\:[0-9a-fA-F]{1,4}){0,1}|\:))|
(([0-9a-fA-F]{1,4}\:){7}\:)|
)\/(
[0-9]{1,2}|(1[01][0-9])|(12[0-8])
))
'

REGEX_IP6="$(echo "$REGEX_IP6" | tr -d '\n')"

# REGEX_I_ADDRESS matches a comma-seperated list of IPv4/IPv6 addresses.
REGEX_I_ADDRESS="^\s*(${REGEX_IP4}|${REGEX_IP6})(\s*,\s*(${REGEX_IP4}|${REGEX_IP6}))*\s*$"

REGEX_P_IPS="$REGEX_I_ADDRESS"


####################
# global variables #
####################

# CONFIG stores the templated configuration for the wireguard-device.
# CONFIG is modified through _addConfigLine
CONFIG=''

#############
# functions #
#############

# _log prints a log-output.
# _log writes a timestamp, info (INFO, OK, ERROR, FATAL) and multiple messages.
# $1=STATUs $2..*=MESSAGES
_log () (
    i=2
    m=''
    while [ $i -le "$#" ]; do
        if [ $i -eq 2 ]; then
            m="$2"
        else
            m="${m}, "
            eval "m=\"\${m}\$${i}\""
        fi
        i=$((i + 1))
    done
    printf '%s: %s: %s\n' \
        "$(date "+%Y-%m-%d %H-%M-%S")" \
        "$1" \
        "$m"
)

# _addConfigLine adds a line to CONFIG.
# $1=LINECONTENT
_addConfigLine () {
    CONFIG="${CONFIG}${1};"
}

# _getConfig returns the usable config from CONFIG.
_getConfig () {
    echo "$CONFIG" | sed 's|;|\n|g'
}

# _hasEnv returns if an env-variable exists.
# $1=VARNAME
_hasEnv () {
    if env | grep "^${1}=" >/dev/null; then
        return 0
    fi
    return 1
}

# _getVar returns the content of a variable.
# $1=VARNAME
_getVar () {
    eval "echo \"\$${1}\""
}

# _finish is the cleanup-function.
# _finish deletes the wireguard-interface, if I_NODESTROY is not set.
_finish () {
    _log 'OK' "shutting down container"
    if [ ! "$I_NODESTROY" = '' ]; then
        exit 0
    fi
    _log 'OK' "destroying ${I_NAME}"
    ip link del "$I_NAME" 1>/dev/null 2>/dev/null
    exit 0
}

########
# main #
########

_log 'INFO' "starting container $(hostname)"

_log 'INFO' 'generating config'

_addConfigLine '[Interface]'

if [ ! "$I_PRIVATEKEY" = '' ]; then
    if [ -e "$I_PRIVATEKEY" ]; then
        x="$(cat "$I_PRIVATEKEY" 2>&1)"
        if [ $? -ne 0 ]; then
            _log 'FATAL' "cant read private-key ${I_PRIVATEKEY}" "$x"
            exit 1
        fi
        I_PRIVATEKEY="$x"
    fi
    x="$(echo "$I_PRIVATEKEY" | wg pubkey 2>&1)"
    if [ $? -ne 0 ]; then
        _log 'FATAL' 'invalid private-key' "$x"
        exit 1
    fi
    _addConfigLine "PrivateKey=${I_PRIVATEKEY}"
    _log 'OK' 'PrivateKey set'
fi

if [ ! "$I_LISTENPORT" = '' ]; then
    if ! echo "$I_LISTENPORT" | grep '^[0-9]\+$' >/dev/null ; then
        _log 'FATAL' "invalid ListenPort ${I_LISTENPORT}"
        exit 1
    elif [ "$(echo "${I_LISTENPORT} > ((2^16)-1)" | bc)" -eq 1 ]; then
        _log 'FATAL' "invalid ListenPort ${I_LISTENPORT}"
        exit 1
    fi
    _addConfigLine "ListenPort=${I_LISTENPORT}"
    _log 'OK' "ListenPort set to ${I_LISTENPORT}"
fi

if [ ! "$I_FWMARK" = '' ]; then
    if ! echo "$I_FWMARK" | grep -E '^([0-9]+)|(0x[0-9a-fA-F]+)$' >/dev/null; then
        _log 'FATAL' "invalid FwMark ${I_FWMARK}"
        exit 1
    fi
    I_FWMARK="$(printf '%d\n' "$I_FWMARK")"
    if [ "$(echo "${I_FWMARK} > ((2^32)-1)" | bc)" -ne 0 ]; then
        _log 'FATAL' "invalid FwMark ${I_FWMARK}"
        exit 1
    fi
    _addConfigLine "FwMark=${I_FWMARK}"
    _log 'OK' "FwMark set to ${I_FWMARK}"
fi

PEERS="$(env |
         grep -o '^P_[0-9a-zA-Z]\+_PUB=' |
         sed 's|_PUB=$||g' |
         sed 's|^P_||g')"

for p in $PEERS; do
    pub="$(_getVar "P_${p}_PUB")"
    x="$(echo "$pub" | wg pubkey 2>&1)"
    if [ $? -ne 0 ]; then
        _log 'FATAL' "peer ${p}" "invalid PublicKey", "$pub", "$x"
        exit 1
    fi
    _addConfigLine "[Peer]"
    _addConfigLine "PublicKey=${pub}"
    psk="$(_getVar "P_${p}_PSK")"
    if [ ! "$psk" = '' ]; then
        if [ -e "$psk" ]; then
            x="$(cat "$psk" 2>&1)"
            if [ $? -ne 0 ]; then
                _log 'FATAL' "peer ${p}" 'cant read preshared-key' "$x"
                exit 1
            fi
            psk="$x"
        fi
        x="$(echo "$psk" | wg pubkey 2>&1)"
        if [ $? -ne 0 ]; then
            _log 'FATAL' "peer ${p}" "invalid P_${p}_PSK" "$x"
            exit 1
        fi
        _addConfigLine "PresharedKey=${psk}"
    fi
    ips="$(_getVar "P_${p}_IPS")"
    if [ ! "$ips" = '' ]; then
        if ! echo "$ips" | grep -E "$REGEX_P_IPS" >/dev/null; then
            _log 'FATAL' "peer ${p}" "invalid AllowedIPs" 'invalid format' "$ips"
            exit 1
        fi
        _addConfigLine "AllowedIPs=${ips}"
    fi
    end="$(_getVar "P_${p}_END")"
    if [ ! "$end" = '' ]; then
        _addConfigLine "Endpoint=${end}"
    fi
    pka="$(_getVar "P_${p}_PKA")"
    if [ ! "$pka" = '' ]; then
        if [ "$pka" = 'off' ]; then
            true
        elif echo "$pka" | grep '^[0-9]\+$' >/dev/null; then
            if [ "$(echo "${pka} > ((2^16)-1)" | bc)" -eq 1 ]; then
                _log 'FATAL' "peer ${p}" 'invalid PersistentKeepAlive' "$pka"
                exit 1
            fi
        else
            _log 'FATAL' "peer ${p}" 'invalid PersistentKeepAlive' "$pka"
            exit 1
        fi
        _addConfigLine "PersistentKeepalive=${pka}"
    fi
    _log 'OK' "added peer ${p}" \
              "PublicKey=${pub}" \
              "PresharedKey=${psk}" \
              "AllowedIPs=${ips}" \
              "Endpoint=${end}" \
              "PersistentKeepalive=${pka}"
done

_log 'OK' 'configuration generated'

_log 'INFO' 'checking interface-options'

if ! echo "$I_NAME" | grep -E '^[0-9a-zA-Z]+$' >/dev/null; then
    _log 'FATAL' 'invalid interface-name' "$I_NAME"
    exit 1
fi
_log 'OK' "interface-name is ${I_NAME}"

if [ ! "$I_ADDRESS" = '' ]; then
    if ! echo "$I_ADDRESS" | grep -E "$REGEX_I_ADDRESS" >/dev/null; then
        _log 'FATAL' 'invalid interface address' "$I_ADDRESS"
        exit 1
    fi
fi

_log 'OK' 'interface-options validated'

create='1'
if [ "$I_CREATE" = '' ] || [ "$I_CREATE" -eq '0' ]; then
    create='0'
fi
reuse='1'
if [ "$I_REUSE" = '' ] || [ "$I_REUSE" -eq '0' ]; then
    reuse='0'
fi
_log 'INFO' 'initialising interface' \
    "Create=$(echo "$create" | sed 's|0|false|g' | sed 's|1|true|g')" \
    "Reuse=$(echo "$reuse" | sed 's|0|false|g' | sed 's|1|true|g')"

if [ "$create" -ne 1 ] && [ "$reuse" -ne 1 ]; then
    _log 'FATAL' 'cant initialize interface' 'create/reuse interface not permitted'
    exit 1
fi

x="$(modprobe wireguard 2>&1)"
if [ $? -ne 0 ]; then
    _log 'ERROR' 'loading wireguard module' "$x"
else
    _log 'OK' 'wireguard module loaded'
fi

if [ -e "/sys/class/net/${I_NAME}" ]; then
    if [ "$reuse" -eq 0 ]; then
        _log 'FATAL' "cant create ${I_NAME}" "${I_NAME} already exist"
        exit 1
    fi
    x="$(wg show "$I_NAME" 2>&1)"
    if [ $? -ne 0 ]; then
        _log 'FATAL' "cant access ${I_NAME}" "$x"
        exit 1
    fi
    _log 'OK' "reusing ${I_NAME}"
else
    if [ "$create" -eq 0 ]; then
        _log 'FATAL' "cant create ${I_NAME}" 'creation not allowed'
        exit 1
    fi
    x="$(ip link add "$I_NAME" type wireguard 2>&1)"
    if [ $? -ne 0 ]; then
        _log 'FATAL' "cant create ${I_NAME}" "$x"
        exit 1
    fi
    _log 'OK' "created ${I_NAME}"
fi

trap '_finish' TERM EXIT

x=$(_getConfig | wg syncconf "$I_NAME" /dev/stdin 2>&1)
if [ $? -ne 0 ]; then
    _log 'FATAL' "error configuring interface" "$x"
    exit 1
fi
_log 'OK' "configured ${I_NAME}"
if echo "$x" | grep '[a-z]' >/dev/null; then
    x="$(echo "$x" | while read  i; do
        echo "$i" | base64
    done)"
    for i in $x; do
        _log 'INFO' "$(echo "$i" | base64 -d)"
    done
fi

ADDR="$(echo "$I_ADDRESS" |
        sed 's|\s||g' |
        sed 's|,|\n|g')"

ADDR="$(echo "$ADDR" | while read a; do
    if echo "$a" | grep -E "^${REGEX_IP4}$" >/dev/null; then
        echo "$a"
        continue
    fi
    sipcalc "$a" |
    grep '^Expanded\sAddress' |
    sed 's|^Expanded\sAddress\s\+-\s||g' |
    sed "s|$|$(echo "$a" | grep -o '/[0-9]\+$')|g"
done)"

INET4="$(ip address show "$I_NAME" |
        grep -o -E "^\s+inet\s${REGEX_IP4}" |
        sed 's|^\s\+inet\s||g')"

INET6="$(ip address show "$I_NAME" |
         grep -o -E "^\s+inet6\s${REGEX_IP6}" |
         sed 's|^\s\+inet6\s||g')"

x="$(echo "$INET6" | while read i; do
    sipcalc "$i" |
    grep '^Expanded\sAddress' |
    sed 's|^Expanded\sAddress\s\+-\s||g' |
    sed "s|$|$(echo "$i" | grep -o '/[0-9]\+$')|g"
done)"
INET6="$x"

INET="$(printf '%s\n%s' "$INET4" "$INET6")"

for i in $INET; do
    if ! echo "$ADDR" | grep -F "$i" >/dev/null; then
        ip address del "$i" dev "$I_NAME"
        _log 'INFO' "deleted address ${i}"
    fi
done

for a in $ADDR; do
    if ! echo "$INET" | grep -F "$a" >/dev/null; then
        x="$(ip address add "$a" dev "$I_NAME" 2>&1)"
        if [ $? -ne 0 ]; then
            _log 'ERROR' "cant add address ${a}" "$x"
        fi
    fi
done

while true; do
    sleep 2
done
