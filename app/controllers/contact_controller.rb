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
        begin
          ContactMailer.send_email(email, subject, body, I18n.locale).deliver_later
          redirect_to new_contact_path, notice: t("contact.success")
        rescue Net::OpenTimeout, Timeout::Error => e
          logger.error "Timeout al enviar el correo de contacto: #{e.class} - #{e.message}"
          flash.now[:alert] = t("contact.errors.timeout")
          render :new, status: :service_unavailable
        rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPUnknownError, Net::SMTPSyntaxError, Net::SMTPFatalError => e
          logger.error "Error SMTP al enviar correo: #{e.class} - #{e.message}"
          flash.now[:alert] = t("contact.errors.smtp")
          render :new, status: :bad_gateway
        rescue SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
          logger.error "Error de red o conexión SMTP: #{e.class} - #{e.message}"
          flash.now[:alert] = t("contact.errors.network")
          render :new, status: :bad_gateway
        rescue => e
          logger.error "Fallo inesperado al enviar correo: #{e.class} - #{e.message}"
          flash.now[:alert] = t("contact.errors.unexpected")
          render :new, status: :internal_server_error
        end
      else
        flash.now[:alert] = I18n.t("contact.errors.missing_fields")
        render :new
      end
    end

  end