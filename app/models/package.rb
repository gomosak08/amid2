class Package < ApplicationRecord
    has_one_attached :image
    validates :image, presence: true
    enum kind: {
    servicios: 'servicios',
    paquete: 'paquete',
    cirugia: 'cirugia'
    }
end
