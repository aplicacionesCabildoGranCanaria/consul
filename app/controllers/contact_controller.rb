class ContactController < ApplicationController
    invisible_captcha only: [:create], honeypot: :spam_bot

    skip_authorization_check

    def new
    end
  
    def create
      email = params[:email]
      subject = params[:subject]
      body = params[:summary]
  
      if email.present? && subject.present? && body.present?
        ContactMailer.send_email(email, subject, body, I18n.locale).deliver_now
        redirect_to new_contact_path, notice: "Tu mensaje ha sido enviado correctamente."
      else
        flash.now[:alert] = "Todos los campos son obligatorios."
        render :new
      end
    end
  end