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
  puts "🔗  #{doctor.name}: #{ids.size} paquetes vinculados"
end

# =========================
# Doctors (2 existentes + 2 nuevos)
# =========================
begin
  base_doctors = [
    { name: "Dr. Salvador C.", specialty: "Cardiology",  email: "salvador@example.com" },
    { name: "Dr. Mariana R.",  specialty: "Dermatology", email: "mariana@example.com" }
  ]

  extra_doctors = [
    { name: "Dr. Juan P.",     specialty: "Radiology",   email: "juanp@example.com"  },
    { name: "Dra. Elena G.",   specialty: "Gynecology",  email: "elena@example.com"  }
  ]

  (base_doctors + extra_doctors).each do |attrs|
    Doctor.find_or_create_by!(email: attrs[:email]) do |d|
      d.name            = attrs[:name]
      d.specialty       = attrs[:specialty]
      d.available_hours = default_hours_json
    end
  end
  puts "✅ Doctors created/ensured."
rescue ActiveRecord::RecordInvalid => e
  puts "❌ Doctor creation failed: #{e.record.errors.full_messages.join(', ')}"
end

# =========================
# Users
# =========================
begin
  [
    { name: "Admin User",     email: "admin@example.com",     password: "admin123",  role: "admin",     admin: true  },
    { name: "Secretary User", email: "secretary@example.com", password: "secret123", role: "secretary", admin: false }
  ].each do |u|
    User.find_or_create_by!(email: u[:email]) do |user|
      user.name     = u[:name]
      user.password = u[:password]
      user.role     = u[:role]
      user.admin    = u[:admin]
    end
  end
  puts "✅ Users created/ensured."
rescue ActiveRecord::RecordInvalid => e
  puts "❌ User creation failed: #{e.record.errors.full_messages.join(', ')}"
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
  "", "", "", "", "", "", "", "",  # ← 8 vacíos
  "– Papanicolau\n– Ultrasonido útero y ovarios\n– Consulta",
  "– Colposcopia\n– Vulvoscopia\n– Papanicolaou\n– Ultrasonido de útero o mamas\n– Consulta\n– Tiempo estimado de duración: 50 minutos\n* Se requiere que la paciente no esté en su periodo menstrual, 24 horas de abstinencia sexual y acudir con ropa cómoda.",
  "– Papanicolaou\n– Vaginoscopía\n– Vulvoscopía\n– Colposcopía\n– Consulta",
  "– Atención de trabajo de parto/cesárea incluye honorarios ginecológicos, pediatra, anestesiólogo\n– Tiempo de estudio 30 minutos\n* Honorarios de hospitalización se cubren por separado.",
  "", "", "", "",  # ← 4 vacíos
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
  "", "", "", "", "", "", "", "", "", "",
  50, "", 30, "", "", "", "",
  20000, 18000, 25000, 20000, 25000, 20000,
  30000, 27000, 18000, 18000, 3500, 15000,
  2000, 7000, 5000
]
# Nota: En tu arreglo original, algunos "time" venían en blanco; si "duration" es obligatorio, conviértelo a nil o a un entero por defecto.
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

  image_path = Rails.root.join("app/assets/images/paquete#{i + 1}.jpg")
  default_image = Rails.root.join("app/assets/images/default.jpg")

  if package.image.attached?
    # ya tiene imagen; no hacemos nada
  else
    if File.exist?(image_path)
      package.image.attach(io: File.open(image_path), filename: "paquete#{i + 1}.jpg", content_type: "image/jpeg")
    elsif File.exist?(default_image)
      package.image.attach(io: File.open(default_image), filename: "default.jpg", content_type: "image/jpeg")
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
  sleep(0.05)
end

# =========================
# Associations Doctor ↔ Package
# =========================
puts "🔧 Linking doctors to packages..."

doc_salvador = Doctor.find_by(email: "salvador@example.com") # Cardiology
doc_mariana  = Doctor.find_by(email: "mariana@example.com")  # Dermatology
doc_juan     = Doctor.find_by(email: "juanp@example.com")    # Radiology
doc_elena    = Doctor.find_by(email: "elena@example.com")    # Gynecology

# Perfiles (ajusta a tu catálogo real si quieres más precisión)
radiology_pkgs = pkgs_by_names_includes(
  "Ultrasonido", "Doppler", "Estructural", "Partes Blandas", "Testicular", "Tiroides",
  "Renal", "Riñón", "Hígado", "Vesícula", "Abdomen", "4D", "5D", "11 a 14 semanas",
  "Rodilla", "Hombro", "Arterial", "Venoso", "Mama"
).or(pkgs_by_kind("servicios"))

gyne_pkgs = pkgs_by_kind("paquete").or(
  pkgs_by_names_includes(
    "Ginecol", "Mujer", "Colposcopia", "Papanicolau", "Cesárea", "Parto",
    "VPH", "Verrugas", "Láser", "Rejuvenecimiento vaginal", "Histeroscopia", "Útero", "Ovarios", "Mama"
  )
)

derm_pkgs = pkgs_by_names_includes(
  "Partes Blandas", "Piel", "Láser", "cicatrices", "estrías", "Verrugas", "Lesión del VPH", "Blanqueamiento íntimo", "Mama"
)

cardio_pkgs = pkgs_by_names_includes(
  "Doppler", "Arterial", "Venoso", "Abdominal", "Hígado", "Vesícula", "Renal", "Tiroides"
)

link_doctor_packages!(doc_juan,     radiology_pkgs) # Radiología
link_doctor_packages!(doc_elena,    gyne_pkgs)      # Ginecología
link_doctor_packages!(doc_mariana,  derm_pkgs)      # Dermatología
link_doctor_packages!(doc_salvador, cardio_pkgs)    # Cardiología

puts "✅ Doctor ↔ Package associations done."
puts "🎉 Seeding finished!"
