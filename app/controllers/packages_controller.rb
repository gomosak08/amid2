# app/controllers/packages_controller.rb
class PackagesController < ApplicationController
  def index
    @packages = Package.all
  end

  def show
    @package = Package.find(params[:id])
  end
end
