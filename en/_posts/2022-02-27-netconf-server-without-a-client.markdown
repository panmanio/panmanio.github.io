---
layout: post
title: "Netconf server without a client: tackling timeout issue"
date: 2022-02-27 22:22:41 +0200
tags: netconf bash libnetconf2 named-pipes
i18n: 2022-02-27_netconf_server_without_a_client
---


Using a [Netconf](https://datatracker.ietf.org/doc/html/rfc6241) client is the desired way of connecting to a Netconf server but I sometimes find it convenient to use the [OpenSSH](https://www.openssh.com) [ssh](https://man.openbsd.org/ssh) client to connect to the server for testing purposes. It's even provided as an example way of connecting to the server in [RFC6242](https://datatracker.ietf.org/doc/html/rfc6242):

```console
[user@client]$ ssh -s server.example.org -p 830 netconf
```

However, when the server is based on [libnetconf2](https://github.com/CESNET/libnetconf2) the connection is quickly interrupted after invoking an RPC. There is a timeout specified at libnetconf2 compilation time on the server-side which happens to be triggered by a newline character included by the terminal to the request just after the message separator (`]]>]]>`). That newline character is treated by the server as the beginning of a new request.


I've found a workaround for that issue with bash redirections and named pipes. We need to create the input pipe:

```console
mkfifo pipe.in
```

Then connect to the server:

```
ssh user@server.example.org -p830 -s netconf <pipe.in &
```

Define a redirection to `pipe.in`:

```console
exec 9>pipe.in
```

Now redirect your request this way:

```console
>&9 echo -n '<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <capabilities>
    <capability>urn:ietf:params:netconf:base:1.0</capability>
  </capabilities>
</hello>]]>]]>'
```

Try to invoke another RPC:

```console
>&9 echo -n '<rpc xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <get/>
</rpc>]]>]]>'
```

No timeout happens! Close the file descriptor when the work is done:

```console
exec 9>&-
```


Note you can't directly write to the input pipe with `echo -n "<request/>" > pipe.in` as it automatically closes the pipe which makes the `ssh` command stop reading the input. We need a way to manually open and close the pipe. That is why I've used exec with a redirection (it modifies the shell state). The same goal could be achieved by using `{varname}>pipe.in` which assigns a new file descriptor number to `varname` and makes the redirection "persists beyond the scope of the command" (see bash manual: [redirections](https://www.gnu.org/software/bash/manual/bash.html#Redirections)).


The solution above does not work when you use password authentication. If that is the case we need to provide a command that outputs the password, which can be done with the [SSH_ASKPASS](https://man.openbsd.org/ssh#SSH_ASKPASS) environment variable. You may also need to set the [SSH_ASKPASS_REQUIRE](https://man.openbsd.org/ssh#SSH_ASKPASS_REQUIRE) variable to `force` (requires OpenSSH 8.4 or newer, use `sshpass` with older versions).


I've prepared a small [s.sh](https://github.com/panmanio/panmanio.github.io/blob/main/code/s.sh) script that wraps all the details. It should be used the same as the `ssh` but there should be no timeouts; additionally there is no need to send the client hello message.
