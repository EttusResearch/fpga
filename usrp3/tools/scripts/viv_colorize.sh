#/bin/bash

# VIV_COLOR_SCHEME must be defined in the environment setup script
case "$VIV_COLOR_SCHEME" in
    default)
        CLR_OFF='tput sgr0'
        ERR_CLR='tput setaf 1'
        CRIWARN_CLR='tput setaf 1'
        WARN_CLR='tput setaf 3'
        ;;
    *)
        CLR_OFF=''
        ERR_CLR=$CLR_OFF
        CRIWARN_CLR=$CLR_OFF
        WARN_CLR=$CLR_OFF
esac

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

while IFS= read -r line
do
    case $(trim $line) in
        ERROR:*)
            eval $ERR_CLR; echo "$line"; eval $CLR_OFF
            ;;
        CRITICAL[[:space:]]WARNING:*)
            eval $CRIWARN_CLR; echo "$line"; eval $CLR_OFF
            ;;
        WARNING:*)
            eval $WARN_CLR; echo "$line"; eval $CLR_OFF
            ;;
        *)
            echo "$line"
    esac
done
