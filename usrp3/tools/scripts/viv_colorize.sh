#/bin/bash

CLR_OFF='tput sgr0'

case "$VIV_COLOR_SCHEME" in
    default)
        ERR_CLR='tput setaf 1'
        CRIWARN_CLR='tput setaf 1'
        WARN_CLR='tput setaf 3'
        ;;
    *)
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
            $ERR_CLR; echo "$line"; $CLR_OFF;
            ;;
        CRITICAL[[:space:]]WARNING:*)
            $CRIWARN_CLR; echo "$line"; $CLR_OFF;
            ;;
        WARNING:*)
            $WARN_CLR; echo "$line"; $CLR_OFF;
            ;;
        *)
            echo "$line"
    esac
done
