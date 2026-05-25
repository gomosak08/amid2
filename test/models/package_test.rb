require "test_helper"

class PackageTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "accepts png images" do
    package = Package.new(name: "Paquete PNG", description: "Test", price: 100, duration: 30, kind: "paquete")

    File.open(Rails.root.join("public/icon.png"), "rb") do |file|
      package.image.attach(io: file, filename: "icon.png", content_type: "image/png")
    end

    assert package.valid?
  end
end
