r1=Role.find_or_create_by_name("admin")
r2=Role.find_or_create_by_name("user")
r3=Role.find_or_create_by_name("agent")

u1=User.find_or_create_by_username("retcon-acc")
u1.password_confirmation = u1.password = "Repelst33ltje"
u1.save
ru1=RolesUser.find_or_create_by_role_id_and_user_id(r1.id, u1.id)

u2=User.find_or_create_by_username("backup1-acc")
u2.password_confirmation = u2.password = "Gimubed00"
u2.save
ru2=RolesUser.find_or_create_by_role_id_and_user_id(r3.id, u2.id)

b1=BackupServer.find_or_create_by_hostname("backup1-acc")
b1.zpool="tank"
b1.max_backups=4
b1.user = u2
b1.save

p1=Profile.find_or_initialize_by_name("Linux")
if p1.new_record?
  p1.save
  p1.exclusive=false
  l=%w{/dev /proc /sys /backup /tmp /var/spool/mqueue* /var/lib/sendmail /var/lib/ntp/proc cdrom/ /var/lib/cyrus/proc/** /var/lib/php5/sess_* /var/lib/amavis/* /var/lib/lxcfs/cgroup /var/log/lastlog /var/tmp /tank}
  l.each do |path|
    p1.excludes.create(:path => path)
  end
end

s1=Server.find_or_create_by_hostname("dummy-acc")
s1.backup_server_id=b1.id
s1.connect_to="127.0.0.1"
if s1.profiles.size == 0
  s1.profiles << p1
end
s1.save
