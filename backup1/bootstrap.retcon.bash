set -e
# exec >/var/tmp/bootstrap.retcon.`date +%F`-`date +%T`.log
# exec 2>&1

if [ "`whoami`" != "retcon" ]; then
  if [ "`hostname|grep -c '\.'`" = "0" -a -e /vagrant/Vagrantfile ]; then
    sudo hostname `grep '^[[:space:]]*os.server_name' /vagrant/Vagrantfile |tr -d "'" |awk '{print $3; exit;}'`
    sudo sh -c 'hostname > /etc/hostname'
  fi
  grep -q "`hostname`$" /etc/hosts || sudo sh -c "echo 127.0.0.1 `hostname` >>/etc/hosts"
  grep -q "retcon-acc" /etc/hosts || sudo sh -c "echo 192.168.1.201 retcon-acc >>/etc/hosts"
  # Here's a poor man's recipy to see if the installed files match what's in git:
  #   diff --unidirectional-new-file -u -r / backup1/files|grep -v '^Only in /'
  sudo rsync -rl /vagrant/files/./ /./
  #ip addr|grep -q eth0:1 || sudo ifup eth0:1
  apt_get_auto() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
  }
  sudo apt-get update -qq && apt_get_auto dist-upgrade
  apt_get_auto install autoconf bison build-essential libssl1.0-dev libyaml-dev libreadline6-dev\
  zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev git libsqlite3-dev subversion libpq-dev\
  zfsutils-linux

  [ -h /bin/pfexec ] || sudo ln -s /usr/bin/sudo /bin/pfexec
  [ -h /usr/bin/pfexec ] || sudo ln -s /usr/bin/sudo /usr/bin/pfexec
  [ -d /usr/gnu/bin ] || sudo mkdir -p /usr/gnu/bin
  [ -h /usr/gnu/bin/sed ] || sudo ln -s `which sed` /usr/gnu/bin/sed
  [ -h /usr/gnu/bin/awk ] || sudo ln -s `which awk` /usr/gnu/bin/awk

  [ -e /etc/rc2.d/S21retcon-acc-zfs-prep ] || sudo update-rc.d retcon-acc-zfs-prep defaults 21 79
  [ -e /etc/rc2.d/S22commander ] || sudo update-rc.d commander defaults 22 78

  grep -q '^retcon:' /etc/passwd || sudo adduser --disabled-password --gecos retcon retcon

  if [ ! -f ~retcon/.ssh/id_rsa ]; then
    rm -rf tmpssh
    mkdir tmpssh
    ssh-keygen -N "" -f tmpssh/id_rsa
    cat tmpssh/id_rsa.pub | sed -e 's/^/from="127.0.0.1" /' >tmpssh/authorized_keys
    sudo mkdir -p /root/.ssh
    sudo su - retcon sh -c 'mkdir -p ~/.ssh'
    sudo install -m 0400 -o root   -g root   tmpssh/id_rsa     /root/.ssh/id_rsa
    sudo install -m 0400 -o retcon -g retcon tmpssh/id_rsa     ~retcon/.ssh/id_rsa
    sudo install -m 0400 -o retcon -g retcon tmpssh/id_rsa.pub ~retcon/.ssh/id_rsa.pub
    sudo sh -c 'cat ~retcon/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys'
  fi

  sudo su retcon "$0" -- "$@"

  # If zpool status errors out, that means that ZFS has not been loaded by the kernel.
  # We reboot to fix that, rather than trying to get modprobe to play ball. Security
  # updates may mean that the kernel we're running now is not the most recent kernel
  # so we need that reboot anyway. If we're not rebooting, try to prep zfs and start
  # commander.
  sudo zpool status || sudo shutdown -r now
  sudo invoke-rc.d retcon-acc-zfs-prep start
  sudo invoke-rc.d commander start
  echo All done
  exit 0
fi

[ -f $HOME/.gemrc ] || echo gem: --no-ri --no-rdoc >$HOME/.gemrc

[ -f $HOME/.ssh/config ] || cat > $HOME/.ssh/config <<"EOD"
Host *
	User root
EOD

cd $HOME

if [ ! -d commander ]; then
  git clone https://github.com/driehuis/commander
fi

if [ ! -d .rbenv ]; then
  git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
  git clone git://github.com/carsomyr/rbenv-bundler.git ~/.rbenv/plugins/bundler
  if ! grep -q rbenv .profile; then
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
    echo 'eval "$(rbenv init -)"' >> ~/.profile
  fi
  . ~/.profile
  bash -l -c 'rbenv install `cat $HOME/commander/.ruby-version`'
fi

bash -l -c 'cd $HOME/commander; which bundle || gem install -v=1.7.6 bundler'
if [ ! -e commander/config/commander.yml ]; then
  cp -i /vagrant/commander.yml commander/config/commander.yml
fi
bash -l -c 'cd $HOME/commander; bundle install'

exit 0
