Challenge 1: Rebuild the app binary
===================================

You hop into the production server and need to figure out why the application
isn't running. Based on the architecture diagram for the app and your knowledge
of your company's deployment pipelines, you know the source code for it should
have been dumped into the directory `/opt/app`. That's probably the best place
to start looking; as a first step, see if you can get the app binary built. Note
that the application is written in Go, so you might need to look up how to build
a Go binary.

Take note of any error messages when trying to build it, and fix any issues you
find.

(NOTE: the built application needs to be named `app`, NOT `main`)
