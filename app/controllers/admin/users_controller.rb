class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_super_admin
  before_action :set_user, only: %i[edit update destroy]

  def index
    @users = User.order(created_at: :desc)
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    safe_params = user_params
    # Seguridad: nunca permitir crear un administrador desde aquí
    safe_params[:role] = "assistant" if safe_params[:role] == "admin"
    
    @user = User.new(safe_params)

    if @user.save
      redirect_to admin_users_path, notice: "Usuario creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Eliminar password del payload si viene vacío para usar devise correctamente
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    safe_params = user_params
    # Seguridad: si tratan de cambiar su rol a admin u otra cosa no permitida
    if safe_params[:role] == "admin" && !@user.admin?
      safe_params[:role] = "assistant"
    end

    if @user.update(safe_params)
      redirect_to admin_users_path, notice: "Usuario actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "No puedes auto-eliminar tu cuenta de administrador."
    elsif @user.admin?
      redirect_to admin_users_path, alert: "Por seguridad, no puedes eliminar a otros administradores desde este panel."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "Usuario eliminado."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :role, :can_upload_results, :phone)
  end

  def require_super_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Acceso denegado. Solo administradores pueden gestionar usuarios."
    end
  end
end
