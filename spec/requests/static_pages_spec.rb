require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /terms and /privacy" do
    it "独自ドメインの問い合わせ先を表示する" do
      get "/terms"
      expect(response.body).to include("support@read-typing.com")

      get "/privacy"
      expect(response.body).to include("support@read-typing.com")
    end
  end
end
