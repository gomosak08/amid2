# app/controllers/packages_controller.rb
class HomeController < ApplicationController
  def index
    @packages = Package.all
  end

  def show
    @package = Package.find(params[:id])
  end
end
