Linux System Breakfixing
========================

In this workshop, teams will work to fix the broken deployment of an application
running on a Linux server.

System Requirements
-------------------

Note that this workshop content was authored on a Debian Linux machine, and so
the various scripts & utilities are written in support of that. There may be a
few instances of code that is non-portable to BSDs like macOS, but should work
fine on WSL.

---

As a ***workshop administrator***, you will need the following:

- A terminal emulator capable of running the `bash` shell program

- [HashiCorp Terraform](https://terraform.io) (if running workshop on a cloud
  platform)

- x

In addition, for local testing you will need [HashiCorp
Vagrant](https://www.vagrantup.com/), and at least one installation of a
supported Vagrant provider. At the time of this writing, those supported
providers were VirtualBox and `libvirt`. If on WSLv2 on Windows, you will have a
MUCH easier time using the `libvirt` provider.

---

***Workshop participants*** will need the following:

- An SSH client
  - On Windows, this is typically `puTTY` as a standalone tool, or Git Bash or
    WSL. macOS should already have the `ssh` client program installed.
  - Note: participants will ***not*** need knowledge of SSH key management, etc.
    -- auth to the team servers will be password-based.

- Little enough knowledge of Linux OSes to not figure out how to cheat `:)`
