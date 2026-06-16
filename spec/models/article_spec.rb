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

      it "userがnilでもvalidであること" do
        article = build(:article, user: nil)
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
    it "userにoptional: trueでbelongs_toしていること" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:optional]).to eq true
    end
  end

  describe "ユニーク制約 (url, user_id)" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:url) { "https://example.com/shared-article" }

    it "同じURLでも別ユーザーなら作成できること" do
      create(:article, url: url, user: user)
      expect {
        create(:article, url: url, user: other_user)
      }.not_to raise_error
    end

    it "同じURLで同じユーザーは作成できないこと" do
      create(:article, url: url, user: user)
      expect {
        create(:article, url: url, user: user)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "同じ URL で user_id が nil のレコードは複数作成できること" do
      create(:article, url: url, user: nil)
      expect {
        create(:article, url: url, user: nil)
      }.not_to raise_error
    end
  end

  describe "expires_atの自動設定" do
    it "未ログインユーザー作成時にexpires_atがセットされること" do
      travel_to Time.zone.local(2026, 1, 1, 12, 0, 0) do
        article = create(:article, user: nil)
        expect(article.expires_at).to eq 7.days.from_now
      end
    end

    it "ログインユーザー作成時にexpires_atはnilのままであること" do
      article = create(:article, user: create(:user))
      expect(article.expires_at).to be_nil
    end
  end

  describe ".expired scope" do
    it "expires_at が現在時刻より過去のレコードのみ返すこと" do
      expired_article = create(:article, user: nil, expires_at: 1.hour.ago)
      future_article = create(:article, user: nil, expires_at: 1.hour.from_now)
      user_article = create(:article, user: create(:user))  # expires_at nil

      expect(Article.expired).to include(expired_article)
      expect(Article.expired).not_to include(future_article)
      expect(Article.expired).not_to include(user_article)
    end
  end

  describe ".cleanup_expired!" do
    it "期限切れのレコードを削除すること" do
      expired_article = create(:article, user: nil, expires_at: 1.hour.ago)
      future_article = create(:article, user: nil, expires_at: 1.hour.from_now)

      expect {
        Article.cleanup_expired!
      }.to change(Article, :count).by(-1)

      expect(Article.exists?(expired_article.id)).to be false
      expect(Article.exists?(future_article.id)).to be true
    end
  end
end
