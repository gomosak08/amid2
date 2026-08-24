class ServicesController < ApplicationController
  def index
    @packages = Package.publicly_listed.order(:name)
  end

  def show
    @package = Package.find(params[:id])
  end
end
