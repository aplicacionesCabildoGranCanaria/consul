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
        ContactMailerJob.perform_later(email, subject, body, I18n.locale)
        redirect_to new_contact_path, notice: t("contact.success")
      else
        flash.now[:alert] = t("contact.errors.missing_fields")
        render :new
      end
    end

  end