Step 3: App runtime management
==============================

Ok great, the app is now available in the right directory! Now that we've got
that sorted out, we need to see why the app wasn't actually running on the
server.

You were left a note suggesting that there might not even be a service
definition on the machine. These days, services like yours are most commonly
managed by a tool called `systemd`, defined in what are called "unit files".
Furthermore, you know that your app's service definition is supposed to be
(aptly) named `app.service`.

See if that service exists on the machine. If not, create it, and get it
running.
