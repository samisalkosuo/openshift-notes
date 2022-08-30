#!/bin/sh

if [ ! -f "bin.tar" ]; then
    echo "bin.tar does not exist"
    exit 1
fi

function extractClients
{
    echo "copying files to /usr/local/bin/"
    tar -xf bin.tar
    cd bin
    chown root:root *
    cd ..
    mv bin/* /usr/local/bin/
    rm -rf bin/

    #set selinux
    semanage fcontext -a -t bin_t /usr/local/bin/coredns
    restorecon -vF  /usr/local/bin/coredns
    semanage fcontext -a -t bin_t /usr/local/bin/gobetween
    restorecon -vF  /usr/local/bin/gobetween

}

extractClients