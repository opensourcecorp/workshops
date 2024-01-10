Challenge 6: Git SSH Setup
==========================

We just got hired by a very famous movie star (who's name may not be disclosed)
to create a new version of our app for their specific use case. Our lead
engineers were working on putting together the new app, but they mysteriously
dissappeared while on a golfing trip a few weeks past. We were told that the
code was about ready to deploy, just hadn't gotten the chance to merge it into
the main branch. See if you can figure out how to get it up and running.

The name of the app is 'carrot-cruncher'. The last dev got the repo set up
somewhere on disk, but they never said where... hopefully you'll able to find
it. When you do, supposedly there was a new working branch pushed to the remote
repo, so you'll need to figure out how to authenticate to that repo.

There was a note in your team's documentation about a process that picks up keys
in the local git server. Supposedly all you had to do was copy some file to the
'ssh-keys/' directory near all the repos and git takes it from there? So I guess
try that? Then clone the remote branches down, then you'll be off to the
races... Good luck!
