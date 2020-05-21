# Acceptance environment for Retcon

This project contains a completely self-contained vagrant environment
to evaluate the Retcon backup manager.

The resulting server is not intended to run in production.

Feel free to tweak this setup to your liking. As distributed, it brings up one backup server
(a server that has a ZFS pool and rsync/ssh access to the network or networks it is intended
to back up), and a retcon master (where the user interface is run and the administration is kept).
Change the Vagrantfiles if you don't like the design choices:

* Uses the vagrant virtualbox driver, with disksize and vbguest plugins
* Bridges both servers to your local network, using 192.168.1.201 and 192.168.1.202

If you change IP addresses, you must also change them in the bootstrap scripts. There is no
templating for now.

Caveats
-------

This project is intented for demonstration and evaluation only! It may or may work for you.

Installing
----------

Install vagrant with the virtualbox plugin. Then:

    cd master
    vagrant up
    cd ../backup1
    vagrant up

Add "192.168.1.201 retcon-acc" to your /etc/hosts. Navigate to http://retcon-acc and enjoy!

Status
------

1. Master server

Functionally complete.

2. Retcon backup server

Functionally complete.

3. If something doesn't work...

You can always `vagrant ssh` to the offending machine, and re-run the bootstrap script:

<pre>
bash /vagrant/bootstrap.retcon.bash
</pre>

General notes
-------------

Even though no formal support will be given, feel free to raise any issues in the issue tracker.
Also, feel free to lift all and sundry from this repo to get a headstart if you do want
to provision retcon for yourself. Just remember: "if you break it, you own the pieces." Well,
at least to the extent the license allows.
