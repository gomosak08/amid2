# app/controllers/admin/packages_controller.rb
module Admin
  class PackagesController < ApplicationController
    # before_action :authenticate_user!
    before_action :require_admin
    before_action :set_package, only: [ :show, :edit, :update, :destroy ]

    def index
      packages = Package.all

      # Buscador por nombre y descripción
      if params[:q].present?
        query = "%#{params[:q].to_s.strip.downcase}%"
        packages = packages.where(
          "LOWER(name) LIKE :q OR LOWER(description) LIKE :q",
          q: query
        )
      end

      # Orden
      @sort = params[:sort].to_s
      packages = case @sort
      when "price_asc"
        packages.order(price: :asc, id: :desc)
      when "price_desc"
        packages.order(price: :desc, id: :desc)
      when "duration_asc"
        packages.order(duration: :asc, id: :desc)
      when "duration_desc"
        packages.order(duration: :desc, id: :desc)
      when "name_asc"
        packages.order(name: :asc)
      when "name_desc"
        packages.order(name: :desc)
      else
        packages.order(id: :desc)
      end

      # Paginación simple
      @per_page = 9
      @page = params[:page].to_i
      @page = 1 if @page < 1

      @total_count = packages.count
      @total_pages = (@total_count.to_f / @per_page).ceil
      @total_pages = 1 if @total_pages < 1
      @page = @total_pages if @page > @total_pages

      offset = (@page - 1) * @per_page
      @packages = packages.offset(offset).limit(@per_page)
    end

    def show
    end

    def new
      @package = Package.new
    end

    def create
      @package = Package.new(package_params)

      if @package.save
        redirect_to admin_package_path(@package), notice: "Package created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if params[:package][:image].present?
        @package.image.attach(params[:package][:image])
      end

      if @package.update(package_params)
        redirect_to admin_package_path(@package), notice: "Package updated successfully."
      else
        flash.now[:alert] = "Failed to update package. Please check the form for errors."
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @package.destroy
      redirect_to admin_packages_path, notice: "Package deleted successfully."
    end

    private

    def set_package
      @package = Package.find(params[:id])
    end

    def package_params
      params.require(:package).permit(
        :name,
        :description,
        :image,
        :price,
        :duration,
        :kind,
        :featured,
        doctor_ids: []
      )
    end

    def require_admin
      redirect_to root_path, alert: "Access denied" unless current_user&.admin?
    end
  end
end
