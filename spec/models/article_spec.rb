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

      it "テキスト入力の記事はURLがなくても有効であること" do
        article = build(:article, source_type: :text, url: nil)
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

    it "記事を削除すると紐づくタイピング結果の記事IDをnilにする" do
      user = create(:user)
      article = create(:article, user: user)
      typing_result = create(:typing_result, user: user, article: article)

      article.destroy

      expect(typing_result.reload.article).to be_nil
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

  describe ".search_by_keyword" do
    let!(:rails_article) { create(:article, :with_user, title: "Rails入門", url: "https://example.com/rails") }
    let!(:zenn_article)  { create(:article, :with_user, title: "Zennの記事", url: "https://zenn.dev/article/1") }
    let!(:other_article) { create(:article, :with_user, title: "Python入門", url: "https://example.com/python") }

    it "titleにキーワードが含まれる記事が返ること" do
      result = Article.search_by_keyword("Rails")
      expect(result).to include(rails_article)
      expect(result).not_to include(zenn_article)
    end

    it "urlにキーワードが含まれる記事が返ること" do
      result = Article.search_by_keyword("zenn")
      expect(result).to include(zenn_article)
      expect(result).not_to include(rails_article)
    end

    it "キーワードが大文字でも一致すること" do
      result = Article.search_by_keyword("RAILS")
      expect(result).to include(rails_article)
    end

    it "キーワードが一致しない記事は返らないこと" do
      result = Article.search_by_keyword("Java")
      expect(result).to be_empty
    end
  end

  describe ".sorted_by" do
    let!(:apple_article)  { travel_to(3.days.ago) { create(:article, :with_user, title: "Apple") } }
    let!(:banana_article) { travel_to(2.days.ago) { create(:article, :with_user, title: "Banana") } }
    let!(:cherry_article) { travel_to(1.day.ago)  { create(:article, :with_user, title: "Cherry") } }

    it '"newest" を指定すると保存日時の新しい順に返ること' do
      expect(Article.sorted_by("newest").to_a).to eq [ cherry_article, banana_article, apple_article ]
    end

    it '"oldest" を指定すると保存日時の古い順に返ること' do
      expect(Article.sorted_by("oldest").to_a).to eq [ apple_article, banana_article, cherry_article ]
    end

    it '"title_asc" を指定するとタイトルの昇順に返ること' do
      expect(Article.sorted_by("title_asc").to_a).to eq [ apple_article, banana_article, cherry_article ]
    end

    it '"title_desc" を指定するとタイトルの降順に返ること' do
      expect(Article.sorted_by("title_desc").to_a).to eq [ cherry_article, banana_article, apple_article ]
    end

    it '不正なキーを指定すると新しい順（デフォルト）に返ること' do
      expect(Article.sorted_by("invalid").to_a).to eq [ cherry_article, banana_article, apple_article ]
    end
  end
end
