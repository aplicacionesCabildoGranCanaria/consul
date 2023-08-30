if Object.const_defined?('NewGoogleRecaptcha')
  NewGoogleRecaptcha.setup do |config|
    config.site_key   = "Rails.application.secrets.recaptcha_site_key"
    config.secret_key = "Rails.application.secrets.recaptcha_secret_key"
    config.minimum_score = 0.5
  end
end
