#!/bin/bash

createPipe() {
  pipeIn=`mktemp`
  rm $pipeIn
  mkfifo $pipeIn
}

runSsh() {
  ssh $@ <$pipeIn &
}

redirect() {
  exec {redir}>$pipeIn
}

setup() {
  createPipe
  runSsh $@
  redirect
}

hello() {
  echo -n '<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
             <capabilities>
               <capability>urn:ietf:params:netconf:base:1.0</capability>
             </capabilities>
           </hello>]]>]]>' >&${redir}
}

cleanup() {
  exec {redir}>&-
  rm $pipeIn
}

trap cleanup EXIT

setup $@
hello

while read -r input; do
  echo -n $input >&${redir}
done < /dev/stdin
