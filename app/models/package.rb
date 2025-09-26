class Package < ApplicationRecord
    has_many :doctor_packages, dependent: :destroy
    has_many :doctors, through: :doctor_packages

    has_one_attached :image
    validates :image, presence: true
    enum kind: {
    servicios: "servicios",
    paquete: "paquete",
    cirugia: "cirugia"
    }
end
