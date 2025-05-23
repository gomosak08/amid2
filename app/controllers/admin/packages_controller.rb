# app/controllers/admin/packages_controller.rb
module Admin
  class PackagesController < ApplicationController
    # before_action :authenticate_user!      # Ensure only logged-in users can access
    before_action :require_admin           # Ensure only admins can access
    before_action :set_package, only: [ :show, :edit, :update, :destroy ]

    def index
      @packages = Package.all
    end

    def show; end

    def new
      @package = Package.new
    end

    def create
      @package = Package.new(package_params) # Let ActiveStorage handle the image

      if @package.save
        redirect_to admin_package_path(@package), notice: "Package created successfully."
      else
        render :new
      end
    end

    def update
      @package = Package.find(params[:id])

      # Attach a new image only if one is provided
      if params[:package][:image].present?
        @package.image.attach(params[:package][:image])
      end
      puts params.inspect

      if @package.update(package_params)
        redirect_to admin_package_path(@package), notice: "Package updated successfully."
      else
        flash[:alert] = "Failed to update package. Please check the form for errors."
        render :edit
      end
    end



    def destroy
      @package.destroy
      redirect_to admin_packages_path, notice: "Package deleted successfully."
    end

    private

    def save_image(uploaded_file)
      # Set the directory where files will be saved
      directory = Rails.root.join("public", "uploads")
      FileUtils.mkdir_p(directory) unless File.directory?(directory)

      # Generate a unique filename
      filename = "#{SecureRandom.hex}_#{uploaded_file.original_filename}"

      # Save the file to the directory
      filepath = directory.join(filename)
      File.open(filepath, "wb") do |file|
        file.write(uploaded_file.read)
      end

      # Return the filename for storage in the database
      filename
    end

    def set_package
      @package = Package.find(params[:id])
    end

    def package_params
      params.require(:package).permit(:name, :description, :image, :price, :duration, :image, :kind, :featured)
    end

    def require_admin
      redirect_to root_path, alert: "Access denied" unless current_user&.admin?
    end
  end
end
