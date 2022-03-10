require_dependency Rails.root.join("app", "models", "setting").to_s

class Setting < ApplicationRecord
  class << self
    alias_method :old_defaults, :defaults
    def defaults
      default_settings = old_defaults
      default_settings["feature.red_sara_service"] = true
      default_settings
    end
  end
end
