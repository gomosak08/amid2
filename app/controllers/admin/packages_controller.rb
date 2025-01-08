# app/controllers/admin/packages_controller.rb
module Admin
  class PackagesController < ApplicationController
    #before_action :authenticate_user!      # Ensure only logged-in users can access
    before_action :require_admin           # Ensure only admins can access
    before_action :set_package, only: [:show, :edit, :update, :destroy]

    def index
      @packages = Package.all
    end

    def show; end

    def new
      @package = Package.new
    end

     def create
      @package = Package.new(package_params) # :image will not be in package_params

      # Handle image upload separately
      if params[:package][:image].present?
        image_name = save_image(params[:package][:image])
        @package.image = image_name # Manually assign the filename to @package.image
        puts params
        
      end

      if @package.save
        redirect_to admin_package_path(@package), notice: 'Package created successfully.'
      else
        render :new
      end
    end

    def update
      @package = Package.find(params[:id])

      # Handle image upload separately in update as well
      if params[:package][:image].present?
        image_name = save_image(params[:package][:image])
        params[:package][:image] = image_name # Manually assign the filename to @package.image
      end

      if @package.update(package_params) # :image will not be in package_params
        redirect_to admin_package_path(@package), notice: 'Package updated successfully.'
      else
        render :edit
      end
    end

    def destroy
      @package.destroy
      redirect_to admin_packages_path, notice: 'Package deleted successfully.'
    end

    private
    
    def save_image(uploaded_file)
      image_name = "#{Time.now.to_i}_#{uploaded_file.original_filename}"
      image_path = Rails.root.join('app', 'assets', 'images', image_name)
  
      # Save the uploaded file to the specified path
      File.open(image_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end
  
      image_name # Return the filename to be saved in the database
    end

    def set_package
      @package = Package.find(params[:id])
    end

    def package_params
      params.require(:package).permit(:name, :description, :image, :price, :duration)
    end

    def require_admin
      redirect_to root_path, alert: 'Access denied' unless current_user&.admin?
    end
  end
end
