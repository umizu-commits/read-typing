require "rails_helper"

RSpec.describe "Sentry configuration" do
  it "sends events only from production" do
    expect(Sentry.configuration.enabled_environments).to eq([ "production" ])
  end

  it "does not send default personally identifiable information" do
    expect(Sentry.configuration.send_default_pii).to be(false)
  end
end
