class SurgeriesController < ApplicationController
  before_action :redirect_to_home

  def index
    @packages = Package.all
  end

  def show
    @package = Package.find(params[:id])
  end

  private

  def redirect_to_home
    redirect_to root_path, alert: "Módulo de cirugías no disponible temporalmente."
  end
end
