puts "🌱 Seeding database..."

# Doctors
begin
  Doctor.create!([
    {
      name: "Dr. Salvador C.",
      specialty: "Cardiology",
      email: "salvador@example.com",
      available_hours: {
        "Monday"    => [ "09:00-17:00" ],
        "Tuesday"   => [ "09:00-17:00" ],
        "Wednesday" => [ "09:00-17:00" ],
        "Thursday"  => [ "09:00-17:00" ],
        "Friday"    => [ "09:00-17:00" ],
        "Saturday"  => [ "09:00-17:00" ],
        "Sunday"    => [ "09:00-17:00" ]
      }.to_json
    },
    {
      name: "Dr. Mariana R.",
      specialty: "Dermatology",
      email: "mariana@example.com",
      available_hours: {
        "Monday"    => [ "09:00-17:00" ],
        "Tuesday"   => [ "09:00-17:00" ],
        "Wednesday" => [ "09:00-17:00" ],
        "Thursday"  => [ "09:00-17:00" ],
        "Friday"    => [ "09:00-17:00" ],
        "Saturday"  => [ "09:00-17:00" ],
        "Sunday"    => [ "09:00-17:00" ]
      }.to_json
    }
  ])
  puts "✅ Doctors created."
rescue ActiveRecord::RecordInvalid => e
  puts "❌ Doctor creation failed: #{e.record.errors.full_messages.join(', ')}"
end

# Users
begin
  [
    {
      name: "Admin User",
      email: "admin@example.com",
      password: "admin123",
      role: "admin",
      admin: true
    },
    {
      name: "Secretary User",
      email: "secretary@example.com",
      password: "secret123",
      role: "secretary",
      admin: false
    }
  ].each do |user_attrs|
    User.find_or_create_by!(email: user_attrs[:email]) do |user|
      user.name     = user_attrs[:name]
      user.password = user_attrs[:password]
      user.role     = user_attrs[:role]
      user.admin    = user_attrs[:admin]
    end
  end

  puts "✅ Users created or already exist."
rescue ActiveRecord::RecordInvalid => e
  puts "❌ User creation failed: #{e.record.errors.full_messages.join(', ')}"
end



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
  true,   # Ultrasonido Abdominal
  true,   # Ultrasonido de Próstata
  true,   # Ultrasonido de Tiroides
  true,   # Ultrasonido Renal
  true,   # Ultrasonido de Embarazo
  true,   # Ultrasonido de Abdomen
  false,  # Ultrasonido de Riñón
  false,  # Ultrasonido de Mama
  false,  # Ultrasonido de Hígado
  false,  # Ultrasonido Testicular
  false,  # Ultrasonido 4D y 5D
  false,  # Ultrasonido 11 a 14 semanas
  false,  # Ultrasonido de Rodilla
  false,  # Ultrasonido de Hombro
  false,  # Ultrasonido Doppler
  false,  # Ultrasonido Estructural
  false,  # Ultrasonido de Partes Blandas
  false,  # Ultrasonido de Vesícula Biliar
  false,  # Ultrasonido Arterial o Venoso
  false,  # Blanqueamiento íntimo
  false,  # Histeroscopia
  false,  # Láser para incontinencia
  false,  # Láser para cicatrices
  false,  # Láser para estrías
  false,  # Láser para VPH
  false,  # Láser para rejuvenecimiento vaginal
  false,  # Láser para verrugas genitales
  true,   # Paquete Ginecológico
  true,   # Paquete Mujer
  true,   # Paquete Colposcopia
  false,  # Parto y Cesárea
  false,  # Vacuna para VPH
  false,  # Biopsia de Cérvix
  false,  # Biopsia de Endometrio
  false,  # Atención Psicológica
  true,   # OTB Laparoscópica
  true,   # OTB Abierta
  true,   # Retiro de Quiste Laparoscópica (Cistectomía)
  false,  # Retiro de Quistes Abierta (Cistectomía)
  false,  # Miomectomía Laparoscópica
  false,  # Miomectomía Abierta
  false,  # Histerectomía Laparoscópica
  false,  # Histerectomía Abierta
  false,  # Parto
  false,  # Cesárea
  false,  # Histeroscopia Diagnostica
  false,  # Histeroscopia Quirúrgica
  false,  # Retiro de Verrugas
  false,  # Retiro de Lesión del VPH con láser
  false   # Electrocirugía para VPH
]

price = [
  399, 399, 399, 399, 499, 399, 399, 399, 399, 599,
  999, 999, 699, 699, 1000, 999, 699, 399, 999, 2000,
  3500, 4000, 1000, 2000, 6000, 4000, 4000, 599, 999, 699,
  18000, 3500, 3500, 3500, 350,
  20000, 18000, 25000, 20000, 25000, 20000,
  30000, 27000, 18000, 18000, 3500, 15000,
  2000,   # Desde $2,000
  7000,   # Desde $7,000
  5000    # Desde $5,000
]

time = [
  30, 30, 30, 30, 40, 40, 30, 30, 30, 30,
  60, 40, 30, 30, 60, 60, 30, 30, 60,
  "", "", "", "", "", "", "", "", "", "",  # 9 blancos
  50,
  "",                                      # 1 blanco
  30,
  "", "", "", ""                           # 4 blancos
]
kind = [
  "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios",
  "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios",
  "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios", "servicios",
  "paquete", "paquete", "paquete", "paquete",
  "servicios", "servicios", "servicios", "servicios", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia",
  "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia", "cirugia"
]



name.each_with_index do |package_name, i|
  image_path = Rails.root.join("app/assets/images/paquete#{i + 1}.jpg")

  package = Package.new(
    name: package_name,
    description: description[i],
    price: price[i],
    duration: time[i],
    featured: feature[i],
    kind: kind[i]
  )

  if File.exist?(image_path)
    package.image.attach(
      io: File.open(image_path),
      filename: "paquete#{i + 1}.jpg",
      content_type: "image/jpeg"
    )
  else
    puts "⚠️ Image file not found for package #{i + 1}: #{image_path}"
    # Optionally attach a default image to avoid validation error:
    default_image = Rails.root.join("app/assets/images/default.jpg")
    if File.exist?(default_image)
      package.image.attach(
        io: File.open(default_image),
        filename: "default.jpg",
        content_type: "image/jpeg"
      )
    end
  end

  if package.save
    puts "✅ Created #{package.name}"
  else
    puts "❌ Failed to create package #{i + 1}: #{package.errors.full_messages.join(', ')}"
  end
  sleep(0.1)
end
