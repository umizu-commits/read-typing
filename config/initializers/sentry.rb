# Sentry sends events only in production, and only when Render provides a DSN.
# This keeps local and test errors out of the production Sentry project.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.enabled_environments = [ "production" ]
  config.environment = Rails.env
  config.send_default_pii = false
end
