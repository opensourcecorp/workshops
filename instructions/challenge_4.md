Challenge 4: Bundling the app as a Debian package
=================================================

You got the `systemd` service running! Awesome job!

But... uh, well. This is embarrassing, but it turns out you were looking at a
rather outdated TAD that your boss gave you. The company's IT Security team no
longer allows "random binaries" to be running workloads in production -- all
services need to be running applications that are installed via the system's
package manager. Since your app is just a loose binary that the `systemd`
service points to directly, this is not allowed.

What you need to do instead is bundle your app as a *Debian Package*. If you
look at the `/opt/app` directory again, you may have noticed that there is a
`dist/` subdirectory there. You need to:

- use that `dist/` directory tree, and the right setup & commands, to build a
  Debian Package out of the app (note: you should use the `tree` command on that
  `dist` directory to see the whole existing tree!)

- install the built package with the Debian package manager

- Create a *new* `systemd` service called `app-deb.service`, which runs the
  correctly-installed app binary.

Once you do that, be sure to check the `systemd` and/or `journald` logs of the
new `app-deb.service` to make sure it's running successfully! (and, just like
the last one, that it would keep running after a reboot)
