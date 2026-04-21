# db/seeds.rb
puts "🌱 Seeding database..."

# =========================
# Helpers
# =========================
def default_hours_json
  {
    "Monday"    => [ "09:00-17:00" ],
    "Tuesday"   => [ "09:00-17:00" ],
    "Wednesday" => [ "09:00-17:00" ],
    "Thursday"  => [ "09:00-17:00" ],
    "Friday"    => [ "09:00-17:00" ],
    "Saturday"  => [ "09:00-17:00" ],
    "Sunday"    => [ "09:00-17:00" ]
  }.to_json
end

def pkgs_by_names_includes(*fragments)
  or_sql = fragments.map { "LOWER(name) LIKE ?" }.join(" OR ")
  binds  = fragments.map { |f| "%#{f.downcase}%" }
  Package.where(or_sql, *binds)
end

def pkgs_by_kind(kind)
  Package.where(kind: kind)
end

def link_doctor_packages!(doctor, relation)
  return unless doctor

  ids = relation.distinct.pluck(:id)
  ids.each do |pid|
    DoctorPackage.find_or_create_by!(doctor_id: doctor.id, package_id: pid)
  end

  puts "🔗 #{doctor.name}: #{ids.size} paquetes vinculados"
end

def upsert_user!(attrs)
  user = User.find_or_initialize_by(email: attrs[:email])
  user.name     = attrs[:name]
  user.password = attrs[:password]
  user.role     = attrs[:role]
  user.admin    = attrs[:admin]
  user.phone    = attrs[:phone]
  user.save!
  user
end

def normalize_phone(phone)
  phone.to_s.gsub(/\D/, "")
end

def pick_package_for(doctor, fallback_packages)
  doctor&.packages&.first || fallback_packages.sample
end

def appointment_attrs(
  patient:,
  doctor:,
  package:,
  start_at:,
  duration_minutes: 60,
  status: "scheduled",
  created_by:,
  scheduled_by:
)
  {
    name:         patient[:name],
    age:          patient[:age],
    email:        patient[:email],
    phone:        patient[:phone],
    sex:          patient[:sex],
    doctor:       doctor,
    package:      package,
    start_date:   start_at,
    end_date:     start_at + duration_minutes.minutes,
    status:       status,
    created_by:   created_by,
    scheduled_by: scheduled_by
  }
end

def upsert_appointment!(attrs)
  appointment = Appointment.find_or_initialize_by(
    email: attrs[:email],
    start_date: attrs[:start_date]
  )
  appointment.assign_attributes(attrs)
  appointment.save!
  appointment
end

# =========================
# Doctors
# =========================
puts "🩺 Creating doctors..."

begin
  doctors_data = [
    {
      name: "Miriam Cecilia Casas Villafan",
      email: "miriamcasasv0393@gmail.com",
      phone: "52 443 336 4269",
      specialty: "Ginecologia"
    },
    {
      name: "Sarahi jazmín mesa guerra",
      email: "sarymg2095@gmail.com",
      phone: "52 443 265 1764",
      specialty: "Ginecologia"
    },
    {
      name: "Salvador Damián molina",
      email: "gredic@hotmail.com",
      phone: "4432363259",
      specialty: "Médico ecografista"
    },
    {
      name: "Brianda Izel Torres Granados",
      email: "brianda_izel02@hotmail.com",
      phone: "52 715 127 4764",
      specialty: "Ginecologia"
    },
    {
      name: "Gabriela Marlene correa romero",
      email: "gabi_mar92@hotmail.com",
      phone: "52 443 436 4003",
      specialty: "Ginecologia"
    },
    {
      name: "Irma sarahi salinas cazares",
      email: "Sarahisalinas800@gmail.com",
      phone: "7221530770",
      specialty: "Ginecologia"
    }
  ]

  doctors_data.each do |attrs|
    specialty = Specialty.find_or_create_by!(name: attrs[:specialty])

    doctor = Doctor.find_or_initialize_by(email: attrs[:email])
    doctor.name            = attrs[:name]
    doctor.specialty_id    = specialty.id
    doctor.available_hours = default_hours_json

    doctor.phone = normalize_phone(attrs[:phone]) if doctor.respond_to?(:phone=)

    doctor.save!
    puts "✅ Doctor creado/actualizado: #{doctor.name}"
  end
rescue ActiveRecord::RecordInvalid => e
  puts "❌ Doctor creation failed: #{e.record.errors.full_messages.join(', ')}"
end

# =========================
# Users
# =========================
puts "👤 Creating admin and assistants..."

begin
  admin_user = upsert_user!(
    name: "Admin General",
    email: "admin@example.com",
    password: "admin123",
    role: "admin",
    admin: true,
    phone: "5550001000"
  )

  assistant_1 = upsert_user!(
    name: "Asistente Uno",
    email: "assistant1@example.com",
    password: "secret123",
    role: "assistant",
    admin: false,
    phone: "5550001001"
  )

  assistant_2 = upsert_user!(
    name: "Asistente Dos",
    email: "assistant2@example.com",
    password: "secret123",
    role: "assistant",
    admin: false,
    phone: "5550001002"
  )

  assistant_3 = upsert_user!(
    name: "Asistente Tres",
    email: "assistant3@example.com",
    password: "secret123",
    role: "assistant",
    admin: false,
    phone: "5550001003"
  )

  puts "✅ Admin y asistentes creados/actualizados."
rescue ActiveRecord::RecordInvalid => e
  puts "❌ User creation failed: #{e.record.errors.full_messages.join(', ')}"
end

# =========================
# Users for Doctors
# =========================
puts "👨‍⚕️ Ensuring doctor users..."

begin
  Doctor.find_each do |doc|
    user = User.find_or_initialize_by(email: doc.email)
    user.name     = doc.name
    user.password = "doctor123"
    user.role     = "doctor"
    user.admin    = false
    user.phone    = doc.respond_to?(:phone) && doc.phone.present? ? doc.phone : "555100#{doc.id.to_s.rjust(4, '0')}"
    user.save!

    if doc.respond_to?(:user_id) && doc.user_id != user.id
      doc.update!(user_id: user.id)
    end

    puts "✅ Usuario doctor asegurado: #{doc.name}"
  end
rescue ActiveRecord::RecordInvalid => e
  puts "❌ Doctor user creation failed: #{e.record.errors.full_messages.join(', ')}"
end

# =========================
# Packages (catálogo)
# =========================
description = [
  "Incluye revisión de Hígado, Vesícula Biliar, Riñones, Bazo y Páncreas.\nSe requiere ayuno de por lo menos 6Hrs. Duración 30 Minutos.",
  "Valoración de próstata y vejiga.\nSe requiere ingerir 2 litros de Agua 1.5hrs antes del estudio. Duración 30 minutos.",
  "Valoración de Tiroides.\nNo se requiere preparación. Duración 30 minutos.",
  "Valoración de riñones y vejiga.\nSe requiere ingerir 2 litros de Agua 1.5hrs antes del estudio. Duración 30 minutos.",
  "– Ultrasonido\n– DVD en la primera\n– Consulta\n– Tiempo estimado de duración: 40 minutos\n* No se requiere preparación a partir de la 5 semana de embarazo.",
  "– Hígado, vía Biliar, ambos Riñones, Bazo y Páncreas\n– Consulta\n– Tiempo estimado de estudio 40 minutos\n* Se requiere no estar en su periodo menstrual y abstinencia sexual de 24 horas",
  "– Ambos Riñones\n– Tiempo estimado de estudio 30 minutos\n* Se requiere no estar en su periodo menstrual y abstinencia sexual de 24 horas.",
  "– Ultrasonido Mamario Bilateral\n– Tiempo estimado de estudio 30 minutos\n* No se requiere preparación.",
  "– Hígado y vía Biliar\n– Consulta\n– Tiempo estimado de duración: 30 minutos\n* Se requiere ayuno de 6 horas.",
  "– Testicular Bilateral\n– Tiempo estimado de estudio: 30 minutos\n* No requiere preparación",
  "– Ultrasonido enfocado a la detección de la cara de tu bebé\n– DVD del estudio\n– Tiempo estimado de estudio 1 hora\n* Se sugiere realizar el ultrasonido de la 22 a 32 semanas de gestación.",
  "Presentarse entre las 11 a 14 semanas de gestación.\nDuración 40 minutos.",
  "Valoración de ligamentos de la rodilla.\nNo se requiere preparación. Duración 30 minutos.",
  "Revisión de manguito rotador.\nNo se requiere preparación. Duración 30 minutos.",
  "– Ultrasonido Doppler con impresión de resultados\n– Tiempo estimado de estudio 1 hora\n* No requiere preparación",
  "Presentarse a partir de las 22 semanas de gestación.\nNo se requiere preparación. Duración 60 minutos.",
  "Revisión de lesiones en área de la piel y músculos\nNo se requiere preparación. Duración 30 minutos.",
  "Valoración de Vesícula Biliar.\nSe requiere ayuno de 6hrs. Duración 30minutos.",
  "Revisión de Arterias o venas por Doppler.\nNo se requiere preparación. Duración 60 min.",
  "", "", "", "", "", "", "", "",
  "– Papanicolau\n– Ultrasonido útero y ovarios\n– Consulta",
  "– Colposcopia\n– Vulvoscopia\n– Papanicolaou\n– Ultrasonido de útero o mamas\n– Consulta\n– Tiempo estimado de duración: 50 minutos\n* Se requiere que la paciente no esté en su periodo menstrual, 24 horas de abstinencia sexual y acudir con ropa cómoda.",
  "– Papanicolaou\n– Vaginoscopía\n– Vulvoscopía\n– Colposcopía\n– Consulta",
  "– Atención de trabajo de parto/cesárea incluye honorarios ginecológicos, pediatra, anestesiólogo\n– Tiempo de estudio 30 minutos\n* Honorarios de hospitalización se cubren por separado.",
  "", "", "", "",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Se requiere consulta de valoración. honorarios hospitalarios se cubren por separado.",
  "Dependiendo extensión de  área afectada, se requiere consulta de valoración.",
  "Dependiendo extensión de  área afectada, se requiere consulta de valoración.",
  "Se requiere valoración."
]

name = [
  "Ultrasonido Abdominal", "Ultrasonido de Próstata", "Ultrasonido de Tiroides",
  "Ultrasonido Renal", "Ultrasonido de Embarazo", "Ultrasonido de Abdomen",
  "Ultrasonido de Riñón", "Ultrasonido de Mama", "Ultrasonido de Hígado", "Ultrasonido Testicular",
  "Ultrasonido 4D y 5D", "Ultrasonido 11 a 14 semanas", "Ultrasonido de Rodilla",
  "Ultrasonido de Hombro", "Ultrasonido Doppler", "Ultrasonido Estructural",
  "Ultrasonido de Partes Blandas", "Ultrasonido de Vesícula Biliar", "Ultrasonido Arterial o Venoso",
  "Blanqueamiento íntimo", "Histeroscopia", "Láser para incontinencia",
  "Láser para cicatrices", "Láser para estrías", "Láser para VPH",
  "Láser para rejuvenecimiento vaginal", "Láser para verrugas genitales", "Paquete Ginecológico",
  "Paquete Mujer", "Paquete Colposcopia", "Parto y Cesárea",
  "Vacuna para VPH", "Biopsia de Cérvix", "Biopsia de Endometrio",
  "Atención Psicológica", "OTB Laparoscópica", "OTB Abierta",
  "Retiro de Quiste Laparoscópica (Cistectomía)", "Retiro de Quistes Abierta (Cistectomía)", "Miomectomía Laparoscópica",
  "Miomectomía Abierta", "Histerectomía Laparoscópica", "Histerectomía Abierta", "Parto",
  "Cesárea", "Histeroscopia Diagnostica", "Histeroscopia Quirúrgica", "Retiro de Verrugas",
  "Retiro de Lesión del VPH con láser", "Electrocirugía para VPH"
]

feature = [
  true, true, true, true, true, true, false, false, false, false,
  false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, true, true, true,
  false, false, false, false, false,
  true, true, true, false, false, false, false, false, false, false,
  false, false, false, false, false
]

price = [
  399, 399, 399, 399, 499, 399, 399, 399, 399, 599,
  999, 999, 699, 699, 1000, 999, 699, 399, 999, 2000,
  3500, 4000, 1000, 2000, 6000, 4000, 4000, 599, 999, 699,
  18000, 3500, 3500, 3500, 350,
  20000, 18000, 25000, 20000, 25000, 20000,
  30000, 27000, 18000, 18000, 3500, 15000,
  2000, 7000, 5000
]

time = [
  30, 30, 30, 30, 40, 40, 30, 30, 30, 30,
  60, 40, 30, 30, 60, 60, 30, 30, 60,
  60, 60, 60, 60, 60, 60, 60, 60, 60, 60,
  60, 60, 60, 60, 60, 60, 60,
  60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60,
  60, 60, 60
]
time = time.map { |t| t.to_i.zero? ? nil : t.to_i }

kind = [
  "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios",
  "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios",
  "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios",
  "paquete", "paquete", "paquete", "paquete",
  "servicios", "servicios", "servicios", "servicios", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia",
  "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia"
]

puts "🧩 Creating packages..."
name.each_with_index do |package_name, i|
  attrs = {
    name:        package_name,
    description: description[i],
    price:       price[i],
    duration:    time[i],
    featured:    feature[i],
    kind:        kind[i]
  }

  package = Package.find_or_initialize_by(name: package_name)
  package.assign_attributes(attrs)

  image_path    = Rails.root.join("app/assets/images/paquete#{i + 1}.jpg")
  default_image = Rails.root.join("app/assets/images/default.jpg")

  if package.respond_to?(:image) && !package.image.attached?
    if File.exist?(image_path)
      package.image.attach(
        io: File.open(image_path),
        filename: "paquete#{i + 1}.jpg",
        content_type: "image/jpeg"
      )
    elsif File.exist?(default_image)
      package.image.attach(
        io: File.open(default_image),
        filename: "default.jpg",
        content_type: "image/jpeg"
      )
      puts "⚠️ default.jpg attached for #{package_name}"
    else
      puts "⚠️ No image found for #{package_name} (no default.jpg either)"
    end
  end

  if package.save
    puts "✅ Created/Updated #{package.name}"
  else
    puts "❌ Failed to upsert package #{i + 1} (#{package_name}): #{package.errors.full_messages.join(', ')}"
  end

  sleep(0.03)
end

# =========================
# Associations Doctor ↔ Package
# =========================
puts "🔧 Linking doctors to packages..."

doctor_miriam   = Doctor.find_by(email: "miriamcasasv0393@gmail.com")
doctor_sarahi   = Doctor.find_by(email: "sarymg2095@gmail.com")
doctor_salvador = Doctor.find_by(email: "gredic@hotmail.com")
doctor_brianda  = Doctor.find_by(email: "brianda_izel02@hotmail.com")
doctor_gabriela = Doctor.find_by(email: "gabi_mar92@hotmail.com")
doctor_irma     = Doctor.find_by(email: "Sarahisalinas800@gmail.com")

ecografista_pkgs = pkgs_by_names_includes(
  "Ultrasonido", "Doppler", "Estructural", "Partes Blandas", "Testicular", "Tiroides",
  "Renal", "Riñón", "Hígado", "Vesícula", "Abdomen", "4D", "5D", "11 a 14 semanas",
  "Rodilla", "Hombro", "Arterial", "Venoso", "Mama", "Mamario", "Obstetrico", "Obstétrico"
).or(pkgs_by_kind("servicios"))

gineco_pkgs = pkgs_by_kind("paquete").or(
  pkgs_by_names_includes(
    "Ginecol", "Mujer", "Colposcopia", "Papanicolau", "Cesárea", "Parto",
    "VPH", "Verrugas", "Láser", "Rejuvenecimiento vaginal", "Histeroscopia",
    "Útero", "Ovarios", "Mama", "Mamario", "Embarazo"
  )
).or(
  pkgs_by_names_includes(
    "Vacuna para VPH", "Biopsia", "Atención Psicológica", "Parto y Cesárea", "Parto", "Cesárea",
    "Histeroscopia Diagnostica", "Histeroscopia Quirúrgica",
    "Retiro de Verrugas", "Retiro de Lesión del VPH con láser", "Electrocirugía para VPH",
    "OTB", "Quiste", "Miomectomía", "Histerectomía"
  )
)

[ doctor_miriam, doctor_sarahi, doctor_brianda, doctor_gabriela, doctor_irma ].each do |doc|
  link_doctor_packages!(doc, gineco_pkgs)
end

link_doctor_packages!(doctor_salvador, ecografista_pkgs)

puts "✅ Doctor ↔ Package associations done."

# =========================
# Appointments
# =========================
puts "📅 Creating mock appointments..."

begin
  admin       = User.find_by(email: "admin@example.com")
  assistants  = User.where(email: [ "assistant1@example.com", "assistant2@example.com", "assistant3@example.com" ]).order(:email).to_a
  doctors     = Doctor.includes(:packages).order(:id).to_a
  all_packages = Package.order(:id).to_a

  if admin.blank?
    puts "⚠️ No se encontró el admin."
  elsif assistants.size < 3
    puts "⚠️ No se encontraron los 3 asistentes."
  elsif doctors.blank? || all_packages.blank?
    puts "⚠️ No hay doctores o paquetes para generar citas."
  else
    assistant1, assistant2, assistant3 = assistants

    patients = [
      { name: "Juan Pérez",        age: 31, email: "juan.perez@example.com",        phone: "5551000001", sex: "M" },
      { name: "María López",       age: 27, email: "maria.lopez@example.com",       phone: "5551000002", sex: "F" },
      { name: "Carlos Ruiz",       age: 44, email: "carlos.ruiz@example.com",       phone: "5551000003", sex: "M" },
      { name: "Ana Torres",        age: 35, email: "ana.torres@example.com",        phone: "5551000004", sex: "F" },
      { name: "Lucía Gómez",       age: 29, email: "lucia.gomez@example.com",       phone: "5551000005", sex: "F" },
      { name: "Pedro Sánchez",     age: 50, email: "pedro.sanchez@example.com",     phone: "5551000006", sex: "M" },
      { name: "Valeria Núñez",     age: 23, email: "valeria.nunez@example.com",     phone: "5551000007", sex: "F" },
      { name: "Miguel Herrera",    age: 40, email: "miguel.herrera@example.com",    phone: "5551000008", sex: "M" },
      { name: "Sofía Castro",      age: 33, email: "sofia.castro@example.com",      phone: "5551000009", sex: "F" },
      { name: "Ricardo Flores",    age: 38, email: "ricardo.flores@example.com",    phone: "5551000010", sex: "M" },
      { name: "Fernanda León",     age: 26, email: "fernanda.leon@example.com",     phone: "5551000011", sex: "F" },
      { name: "Diego Molina",      age: 47, email: "diego.molina@example.com",      phone: "5551000012", sex: "M" },
      { name: "Paola Jiménez",     age: 30, email: "paola.jimenez@example.com",     phone: "5551000013", sex: "F" },
      { name: "Gabriela Soto",     age: 36, email: "gabriela.soto@example.com",     phone: "5551000014", sex: "F" },
      { name: "Alejandro Vega",    age: 42, email: "alejandro.vega@example.com",    phone: "5551000015", sex: "M" },
      { name: "Daniela Romero",    age: 25, email: "daniela.romero@example.com",    phone: "5551000016", sex: "F" },
      { name: "Erika Salas",       age: 34, email: "erika.salas@example.com",       phone: "5551000017", sex: "F" },
      { name: "Héctor Martínez",   age: 45, email: "hector.martinez@example.com",   phone: "5551000018", sex: "M" },
      { name: "Laura Mendoza",     age: 28, email: "laura.mendoza@example.com",     phone: "5551000019", sex: "F" },
      { name: "Patricia Vargas",   age: 39, email: "patricia.vargas@example.com",   phone: "5551000020", sex: "F" }
    ]

    seeds = []

    # scheduled
    seeds << appointment_attrs(
      patient: patients[0],
      doctor: doctors[0],
      package: pick_package_for(doctors[0], all_packages),
      start_at: Time.current + 1.day + 9.hours,
      status: "scheduled",
      created_by: admin,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[1],
      doctor: doctors[1] || doctors[0],
      package: pick_package_for(doctors[1] || doctors[0], all_packages),
      start_at: Time.current + 1.day + 11.hours,
      status: "scheduled",
      created_by: assistant1,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[2],
      doctor: doctors[2] || doctors[0],
      package: pick_package_for(doctors[2] || doctors[0], all_packages),
      start_at: Time.current + 2.days + 10.hours,
      status: "scheduled",
      created_by: admin,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[3],
      doctor: doctors[3] || doctors[0],
      package: pick_package_for(doctors[3] || doctors[0], all_packages),
      start_at: Time.current + 2.days + 12.hours,
      status: "scheduled",
      created_by: assistant2,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[16],
      doctor: doctors[4] || doctors[0],
      package: pick_package_for(doctors[4] || doctors[0], all_packages),
      start_at: Time.current + 5.days + 9.hours,
      status: "scheduled",
      created_by: assistant3,
      scheduled_by: :assistant
    )

    # completed
    seeds << appointment_attrs(
      patient: patients[4],
      doctor: doctors[4] || doctors[0],
      package: pick_package_for(doctors[4] || doctors[0], all_packages),
      start_at: Time.current - 1.day - 2.hours,
      status: "completed",
      created_by: admin,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[5],
      doctor: doctors[5] || doctors[0],
      package: pick_package_for(doctors[5] || doctors[0], all_packages),
      start_at: Time.current - 2.days - 1.hour,
      status: "completed",
      created_by: assistant1,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[6],
      doctor: doctors[0],
      package: pick_package_for(doctors[0], all_packages),
      start_at: Time.current - 3.days - 3.hours,
      status: "completed",
      created_by: admin,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[7],
      doctor: doctors[1] || doctors[0],
      package: pick_package_for(doctors[1] || doctors[0], all_packages),
      start_at: Time.current - 4.days - 2.hours,
      status: "completed",
      created_by: assistant2,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[17],
      doctor: doctors[2] || doctors[0],
      package: pick_package_for(doctors[2] || doctors[0], all_packages),
      start_at: Time.current - 5.days - 2.hours,
      status: "completed",
      created_by: assistant3,
      scheduled_by: :assistant
    )

    # cancelled
    seeds << appointment_attrs(
      patient: patients[8],
      doctor: doctors[2] || doctors[0],
      package: pick_package_for(doctors[2] || doctors[0], all_packages),
      start_at: Time.current + 3.days + 9.hours,
      status: "canceled_by_admin",
      created_by: admin,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[9],
      doctor: doctors[3] || doctors[0],
      package: pick_package_for(doctors[3] || doctors[0], all_packages),
      start_at: Time.current + 3.days + 11.hours,
      status: "canceled_by_admin",
      created_by: assistant3,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[10],
      doctor: doctors[4] || doctors[0],
      package: pick_package_for(doctors[4] || doctors[0], all_packages),
      start_at: Time.current + 4.days + 10.hours,
      status: "canceled_by_admin",
      created_by: admin,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[11],
      doctor: doctors[5] || doctors[0],
      package: pick_package_for(doctors[5] || doctors[0], all_packages),
      start_at: Time.current + 4.days + 12.hours,
      status: "canceled_by_client",
      created_by: assistant1,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[18],
      doctor: doctors[0],
      package: pick_package_for(doctors[0], all_packages),
      start_at: Time.current + 6.days + 10.hours,
      status: "canceled_by_client",
      created_by: assistant2,
      scheduled_by: :assistant
    )

    # no_show
    seeds << appointment_attrs(
      patient: patients[12],
      doctor: doctors[0],
      package: pick_package_for(doctors[0], all_packages),
      start_at: Time.current - 1.day - 5.hours,
      status: "no_show",
      created_by: admin,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[13],
      doctor: doctors[1] || doctors[0],
      package: pick_package_for(doctors[1] || doctors[0], all_packages),
      start_at: Time.current - 2.days - 4.hours,
      status: "no_show",
      created_by: assistant2,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[14],
      doctor: doctors[2] || doctors[0],
      package: pick_package_for(doctors[2] || doctors[0], all_packages),
      start_at: Time.current - 3.days - 6.hours,
      status: "no_show",
      created_by: admin,
      scheduled_by: :assistant
    )
    seeds << appointment_attrs(
      patient: patients[15],
      doctor: doctors[3] || doctors[0],
      package: pick_package_for(doctors[3] || doctors[0], all_packages),
      start_at: Time.current - 4.days - 7.hours,
      status: "no_show",
      created_by: assistant3,
      scheduled_by: :admin
    )
    seeds << appointment_attrs(
      patient: patients[19],
      doctor: doctors[4] || doctors[0],
      package: pick_package_for(doctors[4] || doctors[0], all_packages),
      start_at: Time.current - 6.days - 3.hours,
      status: "no_show",
      created_by: assistant1,
      scheduled_by: :assistant
    )

    created_count = 0

    seeds.each do |attrs|
      appointment = upsert_appointment!(attrs)
      created_count += 1
      puts "✅ Appointment upserted: #{appointment.name} | #{appointment.status} | #{appointment.scheduled_by}"
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Appointment failed for #{attrs[:name]}: #{e.record.errors.full_messages.join(', ')}"
    end

    puts "✅ #{created_count} citas creadas/actualizadas."
  end
rescue StandardError => e
  puts "❌ Appointment creation failed: #{e.message}"
end

puts "🎉 Seeding finished!"
