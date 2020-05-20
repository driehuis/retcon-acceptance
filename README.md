# Acceptance environment for Retcon

This project contains a completely self-contained vagrant environment
to evaluate the Retcon backup manager.

The resulting server is not intended to run in production.

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
