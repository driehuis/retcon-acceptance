set -e
if [ "`whoami`" != "retcon" ]; then
	if [ "`hostname|grep -c '\.'`" = "0" -a -e /vagrant/Vagrantfile ]; then
	    sudo hostname `grep '^[[:space:]]*os.server_name' /vagrant/Vagrantfile |tr -d "'" |awk '{print $3; exit;}'`
	    sudo sh -c 'hostname > /etc/hostname'
	fi
	grep -q "`hostname`$" /etc/hosts || sudo sh -c "echo 127.0.0.1 `hostname` >>/etc/hosts"
	sudo rsync -rl /vagrant/files/./ /./
	distro=bionic
	apt_get_auto() {
	  sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@"
	}
	sudo apt-get update -qq && apt_get_auto dist-upgrade
	apt_get_auto install autoconf bison build-essential libssl1.0-dev libyaml-dev libreadline6-dev\
	 zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev git libsqlite3-dev subversion libpq-dev\
	 nginx
	grep -q '^retcon:' /etc/passwd || sudo adduser --disabled-password --gecos retcon retcon
	exec sudo su "retcon" "$0" -- "$@"
	echo Could not switch to retcon user
	exit 1
fi

[ -f $HOME/.gemrc ] || echo gem: --no-ri --no-rdoc >$HOME/.gemrc

cd $HOME

if [ ! -d retcon-web ]; then
  git clone https://github.com/driehuis/retcon-web
  (cd retcon-web && patch -p1 </vagrant/rails.version.diff)
fi
if [ ! -d retcon-manager ]; then
  git clone https://github.com/driehuis/retcon-manager
fi
# Force retcon-manager to use the same ruby version as retcon-web
cmp -s retcon-web/.ruby-version retcon-manager/.ruby-version || cp retcon-web/.ruby-version retcon-manager/.ruby-version

if [ ! -d .rbenv ]; then
  git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
  git clone git://github.com/carsomyr/rbenv-bundler.git ~/.rbenv/plugins/bundler
  if ! grep -q rbenv .profile; then
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
    echo 'eval "$(rbenv init -)"' >> ~/.profile
  fi
  if [ ! -f ~/.rbenv.bash ]; then
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.rbenv.bash
    echo 'eval "$(rbenv init -)"' >> ~/.rbenv.bash
  fi
  . ~/.profile
  bash -l -c 'rbenv install `cat $HOME/retcon-web/.ruby-version`'
fi

bash -l -c 'cd $HOME/retcon-web; rbenv which bundle || gem install -v=1.7.6 bundler'
bash -l -c 'cd $HOME/retcon-web; rbenv which passenger || gem install -v=4.0.59 passenger'
if [ ! -e retcon-web/config/database.yml ]; then
  cp -i retcon-web/config/database.yml.sample retcon-web/config/database.yml
fi
sudo service nginx restart
if [ ! -e retcon-web/config/.secret ]; then
  ps axuww | md5sum - | cut -b1-32 > retcon-web/config/.secret
fi
bash -l -c 'cd $HOME/retcon-web; bundle install'
bash -l -c 'cd $HOME/retcon-web; bundle exec rake db:migrate'
bash -l -c 'cd $HOME/retcon-web; script/runner /vagrant/seed_acceptance.rb'
#pkill --full passenger || true
#nohup bash -l -c 'cd $HOME/retcon-web; passenger start -p 3001' >passenger.install.log 2>&1 &
[ -e /etc/rc2.d/S*retcon-webapp ] || sudo update-rc.d retcon-webapp defaults
bash -l -c 'cd $HOME/retcon-manager; bundle install'
#pkill --full retcon-manager || true
#nohup bash -l -c 'cd $HOME/retcon-manager; ./bin/retcon-manager' >retcon-manager-start.log 2>&1 &
[ -e /etc/rc2.d/S*retcon-manager ] || sudo update-rc.d retcon-manager defaults
sudo service retcon-webapp stop || true
sudo service retcon-webapp start
sudo service retcon-manager stop || true
sudo service retcon-manager start
