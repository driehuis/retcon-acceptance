# Retcon acceptance environment for Retcon

This project contains a completely self-contained Openstack environment
to evaluate the Retcon backup manager.

The resulting server is not intended to run in production. In particular,
the server is not reboot proof.

Caveats
-------

This project is not finished! It may or may work for you.

Installing
----------

Install vagrant with the Openstack plugin. Source your openrc to make sure
the Openstack environment variables are set. Make sure you can deploy
two servers, with one public (floating) IP address.

Status
------

1. Master server
Functionally complete. After provisioning, run
<pre>
bash /vagrant/bootstrap.retcon.bash
</pre>

2. Retcon backup server
Barely started work.
