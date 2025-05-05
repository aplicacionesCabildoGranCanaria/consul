class ContactMailer < ApplicationMailer
    def send_email(email, asunto, descripcion, locale = I18n.default_locale)
      @email = email
      @asunto = asunto
      @descripcion = descripcion
  
      I18n.with_locale(locale) do
        mail(
          to: Rails.application.secrets.contact_email || 'participadigital@grancanaria.com',
          from: email,
          subject: I18n.t("contact_mailer.subject", subject: asunto)
        )
      end
    end
  end
  