# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  #before_action :require_admin, only: [:destroy_user_session]



  
  private

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied.'
    end
  end
end
