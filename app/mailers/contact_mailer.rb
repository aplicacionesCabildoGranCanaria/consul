class ContactMailer < ApplicationMailer
    def send_email(email, asunto, descripcion, locale = I18n.default_locale)
      @email = email
      @asunto = asunto
      @descripcion = descripcion
  
      I18n.with_locale(locale) do
        mail(
          to: Rails.application.secrets.contact_email,
          from: Rails.application.secrets.contact_email,
          subject: I18n.t("contact_mailer.subject", subject: asunto,
          content_type: "text/html; charset=UTF-8")
        )
      end
    end
  end
  