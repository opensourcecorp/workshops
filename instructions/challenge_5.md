Challenge 5: Fix Networking
===========================

You just got a call from your boss -- turns out there's a different application
running on your server that needs to make a network call to *another* server,
but it hasn't managed to hit that other box in quite some time. Uh oh.

The specifics of this other application on your server don't matter, because
your boss suspects the issue is because of bad firewall rules on *your* machine
that weren't set right when the machine started up.

The first thing you'll need to do is figure out what the other server's IP
address is -- you can get that from a file in your home directory
(`.remote-ip.txt`)

Then, you'll want to figure out what port number the app is trying to use. You
might want to look into a program that lets you find out which ports are open on
a server, and then start filtering down from there. You *do* know that the port
number is:

1. Higher than `6000`

2. *Not* `8080`

3. *Not* managed by the `iptables` tool.

Finally, you will want to figure out what firewall issue your own server has
that seems to be causing problems, and fix it.
