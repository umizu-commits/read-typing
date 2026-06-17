require "rails_helper"

RSpec.describe ArticleForm do
  describe "URLバリデーション" do
    subject(:form) { described_class.new(url: url, user: nil) }

    context "ドメイン名のURLの場合" do
      let(:url) { "https://example.com/article" }

    it "バリデーションが通る" do
        expect(form).to be_valid
    end
  end

    context "IPv4リテラルのURLの場合" do
      let(:url) { "http://1.2.3.4/" }

      it "バリデーションエラーになる" do
        expect(form).not_to be_valid
        expect(form.errors[:url]).to include("にIPアドレスは使用できません")
      end
    end
  
    context "IPv6リテラルのURLの場合" do
      let(:url) { "http://[::1]/" }

      it "バリデーションエラーになる" do
        expect(form).not_to be_valid
        expect(form.errors[:url]).to include("にIPアドレスは使用できません")
      end
    end
  end
end