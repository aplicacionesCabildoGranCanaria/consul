if Object.const_defined?("NewGoogleRecaptcha")
  NewGoogleRecaptcha.setup do |config|
    config.site_key = ENV.fetch("RECAPTCHA_SITE_KEY")
    config.secret_key = ENV.fetch("RECAPTCHA_SECRET_KEY")
    config.minimum_score = 0.5
  end
end