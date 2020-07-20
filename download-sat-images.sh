#!/usr/bin/env bash
urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

function help(){
  echo
  echo "Usage"
  echo
  echo "    ./download-sat-images.sh [FILE] [-h|--help] \\"
  echo "               (-d|--debug) \\"
  echo "               (-e=<engine>|--engine=<engine>)"
  echo
  echo "Options"
  echo
  echo "    -h, --help"
  echo "        Show this information"
  echo "    -d, --debug"
  echo "        optional. \\"
  echo "        echo variables during run. \\"
  echo "    -e, --engine"
  echo "        optional. \\"
  echo "        define which engine to use (CURL or WGET). \\"
  echo "        (ie. (-e=CURL|-e=WGET))"
  echo
}

#################################################

# Parsing arguments passed to the script
#################################################
OPTIONS_ARRAY=()
for i in "$@"
do
case $i in
    -h|--help)
    help
    exit 0
    ;;
    -l=*|--line=*)
    line="${i#*=}"
    shift # past argument=value
    ;;
    -li=*|--login=*)
    login="${i#*=}"
    shift # past argument=value
    ;;
    -e=*|--engine=*)
    currentoption="${i#*=}"
    if [[ $currentoption == 'WGET' || $currentoption == 'CURL' ]]; then
      engine=${i#*=}
    else
      echo "An unrecognized engine was passed. Defaulting to 'CURL'."
    fi
    # repeatable
    # OPTIONS_ARRAY+=("${currentoption}")
    shift # past argument=value
    ;;
    *)
    ;;
esac
done
#################################################

FILE=$1
echo "$FILE"
LINE=${line:-42}
echo "$LINE"
LOGIN=${login:-"https://ers.cr.usgs.gov/login/"}
echo "$LOGIN"
HOST=$(echo $LOGIN | awk -F"/" '{print $3}')
echo "$HOST"
ORIGIN=$(echo $LOGIN | sed 's/\/login\///')
echo "$ORIGIN"
ENGINE=${engine:-"CURL"}
echo "$ENGINE"

if [ "$FILE" ]; then
  if [ "$ENGINE" == "CURL" ]; then
    type curl >/dev/null 2>&1 || { echo >&2 "You must have curl installed to use this script."; exit 1; }
    curl --verbose --cookie-jar cookies.txt -o temp.html "$LOGIN"

    TOKEN=$(sed -n 's/.*name="csrf_token"\s\+value="\([^"]\+\).*/\1/p' temp.html)
    echo "$TOKEN"
    ENCODED_TOKEN=$(urlencode $TOKEN)
    echo "$ENCODED_TOKEN"
    FORMINFO=$(sed -n 's/.*name="__ncforminfo"\s\+value="\([^"]\+\).*/\1/p' temp.html)
    echo "$FORMINFO"
    ENCODED_FORMINFO=$(urlencode $FORMINFO)
    echo "$ENCODED_FORMINFO"

    rm temp.html
  elif [ "$ENGINE" == "WGET" ]; then
    type wget >/dev/null 2>&1 || { echo >&2 "You must have wget installed to use this script."; exit 1; }
    echo "right now the wget version of this script doesn\'t work. I\'m keeping it around in case I have some spare time, (HA!) and want to fix it in the future."
    exit 0
    wget -qO temp.html "$LOGIN"

    TOKEN=$(sed -n 's/.*name="csrf_token"\s\+value="\([^"]\+\).*/\1/p' temp.html)
    echo "$TOKEN"
    ENCODED_TOKEN=$(urlencode $TOKEN)
    echo "$ENCODED_TOKEN"
    FORMINFO=$(sed -n 's/.*name="__ncforminfo"\s\+value="\([^"]\+\).*/\1/p' temp.html)
    echo "$FORMINFO"
    ENCODED_FORMINFO=$(urlencode $FORMINFO)
    echo "$ENCODED_FORMINFO"

    rm temp.html
  fi

  USERNAME=$(cat secrets.txt | awk 'NR==1{print $1}')
  echo "$USERNAME"
  PASSWORD=$(cat secrets.txt | awk 'NR==2{print $1}')
  echo "$PASSWORD"

  if [ "$ENGINE" == "CURL" ]; then
     curl --verbose \
      --cookie cookies.txt \
      --cookie-jar cookies.txt \
      -H "Host: $HOST" \
      -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:70.0) Gecko/20100101 Firefox/70.0" \
      -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
      -H "Accept-Language: en-US,en;q=0.5" \
      -H "Accept-Encoding: gzip, deflate, br" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -H "Origin: $ORIGIN" \
      -H "Connection: keep-alive" \
      -H "Referer: $LOGIN" \
      -H "Upgrade-Insecure-Requests: 1" \
      --data "username=$USERNAME&password=$PASSWORD&csrf_token=$ENCODED_TOKEN&__ncforminfo=$ENCODED_FORMINFO" "$LOGIN"
  elif [ "$ENGINE" == "WGET" ]; then
    wget --debug \
      --max-redirect 1 \
      --header="Host: $HOST" \
      --header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:70.0) Gecko/20100101 Firefox/70.0" \
      --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
      --header="Accept-Language: en-US,en;q=0.5" \
      --header="Accept-Encoding: gzip, deflate, br" \
      --header="Content-Type: application/x-www-form-urlencoded" \
      --header="Origin: $ORIGIN" \
      --header="Connection: keep-alive" \
      --header="Referer: $LOGIN" \
      --header="Upgrade-Insecure-Requests: 1" \
      --keep-session-cookies --save-cookies=cookies.txt \
      --method=POST \
      --body-data="username=$USERNAME&password=$PASSWORD&csrf_token=$ENCODED_TOKEN&__ncforminfo=$ENCODED_FORMINFO" "$LOGIN"
  fi

# exit 0

  if [ "$ENGINE" == "CURL" ]; then
    IFS=$'\r\n' GLOBIGNORE='*' command eval 'LINKS=($(awk -F, "NR>1 && NR<1247{OFS=\",\";print \$$LINE}" "$FILE" | sed "s/browse-link/download/" | sed "s/\(.*\)$/\1\/ZIP\/EE\//"))'
    # echo "${LINKS[@]}"
    for LINK in "${LINKS[@]}"
    do
      if [ ! -f $(echo $LINK | awk -F/ '{print $6}').zip ]; then
        echo "Downloading $LINK"
        curl -L --cookie cookies.txt -o $(echo $LINK | awk -F/ '{print $6}').zip "$LINK"
      fi
    done
    echo "All Done."
  elif [ "$ENGINE" == "WGET" ]; then
    awk -F, "NR>1{OFS=\",\";print \$$LINE}" "$FILE" | sed 's/browse-link/download/' | xargs -l1 wget && echo "All done."
  fi
else
  echo "You must specify an EarthExplorer CSV results file."
  exit 1
fi
