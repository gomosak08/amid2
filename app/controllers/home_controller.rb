# app/controllers/packages_controller.rb
class HomeController < ApplicationController
  def index
    @packages = Package.publicly_listed.order(:name)
  end

  def show
    @package = Package.find(params[:id])
  end
end
