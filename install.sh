#!/usr/bin/env bash

if [[ -f /etc/lsb-release ]]; then
    cat /etc/lsb-release | grep "16.04" > /dev/null
    if [[ $? -eq 0 ]]; then
        if [[ $(uname -m) != "x86_64" ]]; then
            echo "Stacker only supports x86_64 architecture."
            exit 1
        fi
    else
        echo "Stacker only supports Ubuntu."
        exit 1
    fi
else
    echo "Stacker only supports Ubuntu."
    exit 1
fi

echo "Installing Stacker.."

sudo curl -sSL https://raw.githubusercontent.com/santoshbaggam/stacker/master/stacker.sh > stacker

sudo chmod +x ./stacker

sudo cp ./stacker /usr/local/bin/
sudo cp ./stacker /usr/bin/

rm -f stacker

echo "Installed Stacker successfully!"
