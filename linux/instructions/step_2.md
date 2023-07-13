Step 2: Make binary more accessible
===================================

You got the binary rebuilt, great work! However, the app is in kind of a weird
place on the filesystem -- there's nothing *wrong* with apps being under the
`/opt` directory, but there are more common places for it to be found. Plus,
those more-common locations tend to be on the system's `$PATH` variable, which
means applications in those directories can be called from anywhere on the
system. For example, to run the app you just built if you were in any other
directory, you would need to provide the full path, `/opt/app/app` -- and that
can get annoying pretty quick!

The TAD (Technical Architecture Document) spec for your app dictates the
following:

- The app needs to be available under the `/usr/local/bin` directory

- Once there, the app there needs to be named `run-app`, not `app`

- The app source code (including the built binary) need to *remain under
  `/opt/app`* as well

- To prevent possible issues with hotfix rebuilds of the app (like we're doing
  now) causing the rebuild to fall out-of-sync with the right location, the app
  must *not be copied to the correct directory* -- you must find another way to
  have the same file appear in multiple places at once.
