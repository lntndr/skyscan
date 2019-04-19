#!/bin/bash

find . -type f -name "*_USRP.txt" | xargs sed -i "s/,/./g"
find . -type f -name "*_USRP.txt" | xargs sed -i -e "s/[[:space:]]\+/ /g"
find . -type f -name "*_USRP.txt" | xargs sed -i -e "/^[[:space:]]*$/d"
find . -type f -name "*_USRP.txt" | xargs sed -i -e "s/ /,/g"

