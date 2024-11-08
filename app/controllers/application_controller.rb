# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :require_admin, only: [:destroy_user_session]

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || admin_root_path
  end

  
  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied.'
    end
  end
end
