require 'rails_helper'

RSpec.describe "Rack::Attack", type: :request do
  around do |example|
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    example.run
  ensure
    Rack::Attack.cache.store = original_store
  end

  let(:fetcher) { instance_double(ArticleHtmlFetcher) }

  before do
    allow(ArticleHtmlFetcher).to receive(:new).and_return(fetcher)
    allow(fetcher).to receive(:call).and_return(double(success?: false, error_message: "テスト用エラー"))
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

  describe "POST /articles/fetch のレート制限" do
    it "記事保存APIと同じ未ログイン枠を共有する" do
      5.times do
        post "/articles", params: { url: "https://example.com" }
        expect(response.status).not_to eq(429)
      end

      post articles_fetch_path, params: { url: "https://example.com" }, as: :json

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
