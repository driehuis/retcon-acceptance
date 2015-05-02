set -e
sudo rsync -rl /vagrant/files/./ /./
sudo sh -c "echo '# Cleared by $0, using sources.list.d instead' >/etc/apt/sources.list"
wget http://plank.cyso.net/linux/apt.cyso.net.pub.key -q -O - | sudo apt-key add -
sudo apt-get update -qq && sudo apt-get dist-upgrade
sudo apt-get install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev\
 zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev git libsqlite3-dev subversion libpq-dev\
 nginx cyso-firewall
[ -f $HOME/.gemrc ] || echo gem: --no-ri --no-rdoc >$HOME/.gemrc

cd $HOME

if [ ! -d retcon-web ]; then
  git clone https://github.com/driehuis/retcon-web
fi

if [ ! -d .rbenv ]; then
  git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
  git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
  git clone git://github.com/carsomyr/rbenv-bundler.git ~/.rbenv/plugins/bundler
  . ~/.profile
  bash -l -c 'rbenv install `cat $HOME/retcon-web/.ruby-version`'
fi

if ! grep -q rbenv .profile; then
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
  echo 'eval "$(rbenv init -)"' >> ~/.profile
fi

bash -l -c 'cd $HOME/retcon-web; which bundle || gem install -v=1.7.6 bundler'
bash -l -c 'cd $HOME/retcon-web; which passenger || gem install -v=4.0.59 passenger'
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
nohup bash -l -c 'cd $HOME/retcon-web; passenger start -p 3001' >passenger.install.log 2>&1 &
