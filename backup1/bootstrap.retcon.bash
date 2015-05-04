set -e
exec >/var/tmp/bootstrap.retcon.`date +%F`-`date +%T`.log
exec 2>&1
grep -q "`hostname`$" /etc/hosts || sudo sh -c "echo 127.0.0.1 `hostname` >>/etc/hosts"
grep -q "retcon-acc" /etc/hosts || sudo sh -c "echo 172.17.1.116 retcon-acc >>/etc/hosts"
sudo rsync -rl /vagrant/files/./ /./
ip addr|grep -q eth0:1 || sudo ifup eth0:1
sudo sh -c "echo '# Cleared by $0, using sources.list.d instead' >/etc/apt/sources.list"
if [ ! -f /etc/apt/sources.list.d/zfs-native-stable-trusty.list ]; then
  sudo add-apt-repository --yes ppa:zfs-native/stable
fi
wget http://plank.cyso.net/linux/apt.cyso.net.pub.key -q -O - | sudo apt-key add -
apt_get_auto() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
}
sudo apt-get update -qq && apt_get_auto dist-upgrade
apt_get_auto install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev\
 zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev git libsqlite3-dev subversion libpq-dev\
 cyso-firewall ubuntu-zfs
sudo chmod 4755 /sbin/zfs /sbin/zpool
sudo zpool status || shutdown -r now
if [ ! -f /var/tmp/zfs-tank-disk0.img ]; then
 sudo dd if=/dev/zero of=/var/tmp/zfs-tank-disk0.img bs=4M count=2000
fi
if sudo zpool list | grep -q 'no pools'; then
 sudo zpool import tank || sudo zpool create tank /var/tmp/zfs-tank-disk0.img
fi

[ -h /bin/pfexec ] || sudo ln -s /usr/bin/sudo /bin/pfexec
[ -h /usr/bin/pfexec ] || sudo ln -s /usr/bin/sudo /usr/bin/pfexec
[ -d /usr/gnu/bin ] || sudo mkdir -p /usr/gnu/bin
[ -h /usr/gnu/bin/sed ] || sudo ln -s `which sed` /usr/gnu/bin/sed
[ -h /usr/gnu/bin/awk ] || sudo ln -s `which awk` /usr/gnu/bin/awk

[ -f $HOME/.gemrc ] || echo gem: --no-ri --no-rdoc >$HOME/.gemrc

cd $HOME

if [ ! -f .ssh/id_rsa ]; then
  ssh-keygen -N '' -f .ssh/id_rsa
  cat .ssh/id_rsa.pub | sed -e 's/^/from="127.0.0.1" /' >>.ssh/authorized_keys
  sudo cp $HOME/.ssh/id_rsa /root/.ssh
  cat .ssh/id_rsa.pub | sed -e 's/^/from="127.0.0.1" /' | sudo sh -c 'cat >>/root/.ssh/authorized_keys'
fi

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
pkill --full commander || true
nohup bash -l -c 'cd $HOME/commander; bin/commander </dev/null' >commander.start.log 2>&1 &
echo All done
exit 0
