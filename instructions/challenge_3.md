Challenge 3: App runtime management
===================================

Ok great, the app is now available in the right directory! Now that we've got
that sorted out, we need to see why the app wasn't actually running on the
server.

You were left a note suggesting that there might not even be a service
definition on the machine. These days, services like yours are most commonly
managed by a tool called `systemd`, defined in what are called "unit files".
Furthermore, you know that your app's service definition is supposed to be
(aptly) named `app.service`.

Create that service, and get it running. You need to make sure it runs *even if
the system reboots* -- meaning that if the server is restarted for any reason,
the app service needs to start again *without you starting it manually*.

If for any reason you need to check out more detailed logs of the service, you
can also use the separate `journalctl` command to inspect them.
