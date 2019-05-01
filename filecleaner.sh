#!/bin/bash
find . -type f -name "*_USRP.txt" | xargs sed -i '/^\s*$/d'
find . -type f -name "*_USRP.txt" | xargs sed -i "s/,/./g"
find . -type f -name "*_USRP.txt" | xargs sed -i "s/[[:space:]]\+/,/g"
