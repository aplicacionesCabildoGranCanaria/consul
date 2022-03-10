module Consul
  class Application < Rails::Application
    config.i18n.default_locale = :es
    config.i18n.available_locales = [:es]

    config.autoload_paths << Rails.root.join('lib/custom')
  end
end
