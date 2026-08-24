class AddKindsToPackages < ActiveRecord::Migration[7.2]
  def up
    if connection.adapter_name == "PostgreSQL"
      add_column :packages, :kinds, :string, array: true, default: [], null: false

      execute <<~SQL
        UPDATE packages
        SET kinds = ARRAY[
          CASE kind
            WHEN 'servicios' THEN 'servicio'
            WHEN 'Ultrasonido' THEN 'ultrasonido'
            WHEN 'Ultrasonidos' THEN 'ultrasonido'
            WHEN 'Servicio Especiale' THEN 'servicio_especial'
            WHEN 'Servicios Especiales' THEN 'servicio_especial'
            ELSE kind
          END
        ]
        WHERE kind IS NOT NULL
          AND kind <> ''
          AND kind <> 'cirugia';
      SQL
    else
      add_column :packages, :kinds, :text, default: "[]", null: false

      Package.reset_column_information
      Package.find_each do |package|
        normalized = normalize_kind(package.kind)
        package.update_column(:kinds, [ normalized ]) if normalized
      end
    end
  end

  def down
    remove_column :packages, :kinds
  end

  private

  def normalize_kind(kind)
    return if kind.blank? || kind == "cirugia"

    {
      "servicios" => "servicio",
      "Ultrasonido" => "ultrasonido",
      "Ultrasonidos" => "ultrasonido",
      "Servicio Especiale" => "servicio_especial",
      "Servicios Especiales" => "servicio_especial"
    }.fetch(kind, kind)
  end
end
