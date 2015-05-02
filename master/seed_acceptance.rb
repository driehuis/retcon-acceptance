u=User.find_or_create_by_username("retcon-acc")
u.password_confirmation = u.password = "Repelst33ltje"
u.save
r1=Role.find_or_create_by_name("admin")
r2=Role.find_or_create_by_name("user")
r3=Role.find_or_create_by_name("agent")
ru=RolesUser.find_or_create_by_role_id_and_user_id(r1.id, u.id)
