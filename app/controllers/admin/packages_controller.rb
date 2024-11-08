# app/controllers/admin/packages_controller.rb
module Admin
    class PackagesController < ApplicationController
      before_action :authenticate_user!   # Ensures only logged-in users can access
      before_action :require_admin        # Ensures only admins can access
      before_action :set_package, only: [:show, :edit, :update, :destroy]
  
      def index
        @packages = Package.all
      end
  
      def show
        # Display details for a single package
      end
  
      def new
        @package = Package.new
      end
  
      def create
        @package = Package.new(package_params)
        if @package.save
          redirect_to admin_packages_path, notice: 'Package created successfully.'
        else
          render :new
        end
      end
  
      def edit
        # Edit form for a package
      end
  
      def update
        if @package.update(package_params)
          redirect_to admin_packages_path, notice: 'Package updated successfully.'
        else
          render :edit
        end
      end
  
      def destroy
        @package.destroy
        redirect_to admin_packages_path, notice: 'Package deleted successfully.'
      end
  
      private
  
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
  