require_dependency Rails.root.join("app", "controllers", "users", "registrations_controller").to_s

class Users::RegistrationsController < Devise::RegistrationsController

  before_action :check_recaptcha , only: [:create]
  def check_recaptcha
    NewGoogleRecaptcha.human?(
      params[:new_google_recaptcha_token],
      "user",
      NewGoogleRecaptcha.minimum_score,
      resource)
  end
end
