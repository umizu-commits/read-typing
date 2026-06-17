require "rails_helper"

RSpec.describe ArticleHtmlFetcher do
  subject(:result) { described_class.new(url).call }

  let(:url) { "https://example.com/article" }

  # Net::HTTPResponse のダブル（偽物）を作るヘルパー
  def build_response(code:, content_type: "text/html; charset=utf-8", body: "<html>test</html>")
    instance_double(Net::HTTPResponse, code: code.to_s).tap do |r|
      allow(r).to receive(:[]).with("content-type").and_return(content_type)
      allow(r).to receive(:read_body) { |&block| block.call(body) if block }
    end
  end

  def stub_ssrf_get(response)
    allow(SsrfFilter).to receive(:get) do |_url, _opts, &block|
      block.call(response)
      response
    end
  end

  context "正常なHTMLを取得できる場合" do
    before { stub_ssrf_get(build_response(code: 200)) }

    it "成功結果を返す" do
      expect(result.success?).to be true
      expect(result.html).to eq("<html>test</html>")
    end
  end

  context "MAX_BODY_SIZEを超えるボディの場合" do
    before do
      large_response = instance_double(Net::HTTPResponse, code: "200").tap do |r|
        allow(r).to receive(:read_body) do |&block|
        block.call("a" * (ArticleHtmlFetcher::MAX_BODY_SIZE + 1))
      end
    end
    stub_ssrf_get(large_response)
  end

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("ファイルサイズが大きすぎます")
    end
  end

  context "Content-TypeがHTMLでない場合" do
    before { stub_ssrf_get(build_response(code: 200, content_type: "application/json")) }

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("HTMLではないため取得できません")
    end
  end

  context "404レスポンスの場合" do
    before { stub_ssrf_get(build_response(code: 404)) }

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("ページが見つかりませんでした")
    end
  end

  context "プライベートIPへのアクセスの場合" do
    before do
      allow(SsrfFilter).to receive(:get).and_raise(SsrfFilter::PrivateIPAddress)
    end

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("アクセスできないURLです")
    end
  end

  context "リダイレクトが多すぎる場合" do
    before do
      allow(SsrfFilter).to receive(:get).and_raise(SsrfFilter::TooManyRedirects)
    end

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("リダイレクトが多すぎます")
    end
  end

  context "接続に失敗した場合" do
    before { allow(SsrfFilter).to receive(:get).and_raise(SocketError) }

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("接続に失敗しました")
    end
  end

  context "タイムアウトの場合" do
    before { allow(SsrfFilter).to receive(:get).and_raise(Net::OpenTimeout) }

    it "エラー結果を返す" do
      expect(result.success?).to be false
      expect(result.error_message).to eq("応答が遅すぎます")
    end
  end
end
