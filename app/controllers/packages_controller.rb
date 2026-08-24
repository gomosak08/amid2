# app/controllers/packages_controller.rb
class PackagesController < ApplicationController
  def index
    @packages = Package.with_kind("paquete").order(:name)
  end

  def show
    @package = Package.find(params[:id])
  end
end
