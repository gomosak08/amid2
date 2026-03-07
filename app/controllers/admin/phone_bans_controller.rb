module Admin
  class PhoneBansController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_phone_ban, only: [ :edit, :update, :destroy, :toggle_active ]

    def index
      @phone_bans = PhoneBan.order(active: :desc, created_at: :desc)
    end

    def new
      @phone_ban = PhoneBan.new
    end

    def create
      phone_e164 = PhoneNormalizer.to_e164(phone_ban_params[:phone])

      @phone_ban = PhoneBan.new(
        phone_e164: phone_e164,
        level: phone_ban_params[:level],
        source: :manual,
        reason: phone_ban_params[:reason],
        active: phone_ban_params[:active].present? ? ActiveModel::Type::Boolean.new.cast(phone_ban_params[:active]) : true,
        expires_at: phone_ban_params[:expires_at].presence,
        created_by: current_user
      )

      if phone_e164.blank?
        @phone_ban.errors.add(:phone_e164, "no es válido")
        render :new, status: :unprocessable_entity
        return
      end

      if @phone_ban.save
        redirect_to admin_phone_bans_path, notice: "Baneo creado correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = {
        level: phone_ban_params[:level],
        reason: phone_ban_params[:reason],
        expires_at: phone_ban_params[:expires_at].presence,
        active: ActiveModel::Type::Boolean.new.cast(phone_ban_params[:active])
      }

      if phone_ban_params[:phone].present?
        attrs[:phone_e164] = PhoneNormalizer.to_e164(phone_ban_params[:phone])
      end

      if @phone_ban.update(attrs)
        redirect_to admin_phone_bans_path, notice: "Baneo actualizado correctamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      @phone_ban.update!(active: !@phone_ban.active)
      redirect_to admin_phone_bans_path, notice: "Estado del baneo actualizado correctamente."
    end

    def destroy
      @phone_ban.destroy!
      redirect_to admin_phone_bans_path, notice: "Baneo eliminado correctamente."
    end

    private

    def set_phone_ban
      @phone_ban = PhoneBan.find(params[:id])
    end

    def phone_ban_params
      params.require(:phone_ban).permit(:phone, :level, :reason, :expires_at, :active)
    end
  end
end
