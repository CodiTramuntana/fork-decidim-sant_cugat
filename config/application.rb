require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DecidimSantCugat
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Madrid'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false

    # Locales
    config.i18n.available_locales = %w(ca)
    config.i18n.default_locale = :ca
  end
end
