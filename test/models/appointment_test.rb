require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "canceled appointments do not block the same slot" do
    doctor = Doctor.create!(name: "Dra. Libre", email: "libre@example.com")
    package = Package.new(name: "Consulta", duration: 30, price: 100, kind: "servicios")
    package.save!(validate: false)
    DoctorPackage.create!(doctor: doctor, package: package)

    starts_at = Time.zone.local(2026, 5, 10, 10, 0, 0)

    Appointment.create!(
      name: "Paciente cancelado",
      age: 30,
      phone: "5555555555",
      doctor: doctor,
      package: package,
      status: :canceled_by_admin,
      start_date: starts_at,
      end_date: starts_at + 30.minutes,
      duration: 30,
      canceled_at: Time.current
    )

    replacement = Appointment.new(
      name: "Paciente nuevo",
      age: 31,
      phone: "5555555556",
      doctor: doctor,
      package: package,
      status: :scheduled,
      start_date: starts_at,
      end_date: starts_at + 30.minutes,
      duration: 30
    )

    assert replacement.valid?
  end
end
