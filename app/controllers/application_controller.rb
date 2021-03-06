# encoding: utf-8
# frozen_string_literal: true
class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  check_authorization unless: :unauthorized_controllers

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  before_action :authenticate_user!, :set_default_nav
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_user_cookie, if: :user_signed_in?

  private def current_account
    @current_account ||= begin
      if current_user.present?
        current_user.account
      elsif request.subdomain.present? && request.subdomain != "www" && request.subdomain != "api"
        Account.where(subdomain: request.subdomain).first
      end
    end
  end
  helper_method :current_account

  private def unauthorized_controllers
    devise_controller?
  end

  private def set_user_cookie
    cookies.signed[:cable] = {
      id: current_user.id,
      expires_at: 30.minutes.from_now
    }.to_json
  end

  private def set_default_nav
    @active_nav = 'home'
  end

  private def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "desc"
  end
  helper_method :sort_direction

  private def backend?
    self.class.to_s.split("::").first == "Backend"
  end
  helper_method :backend?

  private def registration_enabled?
    Rails.application.secrets[:registration]
  end
  helper_method :registration_enabled?

  private def invoice_limit_reached?
    !current_user.admin? && Rails.application.secrets[:demo] && current_account.invoices.count >= 2
  end
  helper_method :invoice_limit_reached?

  private def api_domain
    "//api.#{Rails.application.secrets[:domain]}"
  end
  helper_method :api_domain

  private def store_current_params
    key = (params[:controller].to_s + "_" + params[:action].to_s).to_sym
    session[key] = params.reject { |k| %w(controller action format).include?(k.to_s) }
  end

  private def stored_params(action, controller = params[:controller])
    key = (controller.to_s + "_" + action.to_s).to_sym
    (session[key] || ActionController::Parameters.new).to_unsafe_h
  end
  helper_method :stored_params

  protected def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
