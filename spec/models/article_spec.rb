require "rails_helper"

RSpec.describe Article, type: :model do
  describe "バリデーション" do
    let(:article) { build(:article) }

    context "正常系" do
      it "有効なデータの場合、バリデーションが通ること" do
        expect(article).to be_valid
      end

      it "titleがnilの場合でもバリデーションが通ること" do
        article.title = nil
        expect(article).to be_valid
      end
    end

    context "urlのバリデーション" do
      it "urlが空の場合、無効であること" do
        article.url = nil
        expect(article).not_to be_valid
      end

      it "urlがhttp/https以外の場合、無効であること" do
        article.url = "ftp://example.com"
        expect(article).not_to be_valid
      end

      it "urlが正しい形式の場合、有効であること" do
        article.url = "https://example.com/valid-url"
        expect(article).to be_valid
      end
    end

    context "bodyのバリデーション" do
      it "bodyが空の場合、無効であること" do
        article.body = nil
        expect(article).not_to be_valid
      end
    end
  end

  describe "アソシエーション" do
    it "userに紐づいていること" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end
  end
end
