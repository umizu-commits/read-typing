require 'rails_helper'

RSpec.describe "Rack::Attack", type: :request do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    allow_any_instance_of(ArticleHtmlFetcher).to receive(:call).and_return(
      double(success?: false, error_message: "テスト用エラー")
    )
  end

  describe "POST /articles のレート制限" do
    context "未ログインユーザーの場合" do
      it "5回目まではリクエストが通る" do
        5.times do
          post "/articles", params: { url: "https://example.com" }
          expect(response.status).not_to eq(429)
        end
      end

      it "6回目以降は429を返す" do
        5.times { post "/articles", params: { url: "https://example.com" } }
        post "/articles", params: { url: "https://example.com" }
        expect(response.status).to eq(429)
      end
    end

    context "ログインユーザーの場合" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "10回目まではリクエストが通る" do
        10.times do
          post "/articles", params: { url: "https://example.com" }
          expect(response.status).not_to eq(429)
        end
      end

      it "11回目以降は429を返す" do
        10.times { post "/articles", params: { url: "https://example.com" } }
        post "/articles", params: { url: "https://example.com" }
        expect(response.status).to eq(429)
      end

      it "5回を超えてもIPのthrottleには引っかからない" do
        6.times do
          post "/articles", params: { url: "https://example.com" }
          expect(response.status).not_to eq(429)
        end
      end
    end
  end
end
