class ContactController < ApplicationController
    invisible_captcha only: [:create], honeypot: :spam_bot

    skip_authorization_check

    def new
    end
  
    def create
      email = params[:email].to_s.strip
      subject = params[:subject].to_s.strip.gsub(/[\r\n]/, ' ')
      body = params[:summary].to_s

      unless email.match?(URI::MailTo::EMAIL_REGEXP)
        flash.now[:alert] = t("contact.form.invalid_email")
        return render :new
      end

      if email.present? && subject.present? && body.present?
        ContactMailerJob.perform_later(email, subject, body, I18n.locale)
        redirect_to new_contact_path, notice: t("contact.success")
      else
        flash.now[:alert] = t("contact.errors.missing_fields")
        render :new
      end
    end

  end
