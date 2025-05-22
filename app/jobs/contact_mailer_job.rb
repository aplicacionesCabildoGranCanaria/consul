class ContactMailerJob < ApplicationJob
  queue_as :default

  rescue_from(Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPUnknownError,
              Net::SMTPSyntaxError, Net::SMTPFatalError) do |exception|
    Rails.logger.error "[ContactMailerJob] Error SMTP: #{exception.class} - #{exception.message}"
  end

  rescue_from(SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError) do |exception|
    Rails.logger.error "[ContactMailerJob] Error de red: #{exception.class} - #{exception.message}"
  end

  rescue_from(StandardError) do |exception|
    Rails.logger.error "[ContactMailerJob] Error inesperado: #{exception.class} - #{exception.message}"
  end

  def perform(email, subject, body, locale = I18n.default_locale)
    Rails.logger.info "[ContactMailerJob] Enviando email a #{email}..."
    ContactMailer.send_email(email, subject, body, locale).deliver_now
  end
end
