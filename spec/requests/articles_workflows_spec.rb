require "rails_helper"

RSpec.describe "記事の作成・取得・お気に入り", type: :request do
  let(:user) { create(:user) }
  let(:url) { "https://example.com/articles/1" }

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  describe "POST /articles" do
    context "テキストを保存する場合" do
      before { sign_in user }

      it "記事を保存してタイピング画面へ遷移する" do
        expect {
          post articles_path, params: {
            source_type: "text",
            title: "手入力の記事",
            body: "あ" * 50,
            category: "tech",
            tag_names: "Rails, Ruby"
          }
        }.to change(Article, :count).by(1)

        article = Article.last
        expect(article).to have_attributes(
          user: user,
          source_type: "text",
          title: "手入力の記事",
          category: "tech"
        )
        expect(article.tags.pluck(:name)).to match_array([ "Rails", "Ruby" ])
        expect(response).to redirect_to(typing_path(article_id: article.id))
      end

      it "save_only指定時は保存記事一覧へ遷移する" do
        post articles_path, params: {
          source_type: "text",
          body: "あ" * 50,
          save_only: "true"
        }

        expect(response).to redirect_to(articles_path)
      end

      it "短すぎる本文は保存しない" do
        expect {
          post articles_path, params: {
            source_type: "text",
            body: "あ" * 49
          }
        }.not_to change(Article, :count)

        expect(response).to redirect_to(root_path)
      end

      it "長すぎるタグ名では500にせず保存しない" do
        expect {
          post articles_path, params: {
            source_type: "text",
            body: "あ" * 50,
            tag_names: "a" * 21
          }
        }.not_to change(Article, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "URLから保存する場合" do
      let(:fetcher) { instance_double(ArticleHtmlFetcher) }
      let(:extractor) { instance_double(ArticleBodyExtractor) }
      let(:preprocessor) { instance_double(TypingTextPreprocessor) }
      let(:fetch_result) do
        ArticleHtmlFetcher::Result.new(success?: true, html: "<html></html>", error_message: nil)
      end
      let(:extract_result) do
        ArticleBodyExtractor::Result.new(success?: true, body: "あ" * 50, title: "取得記事", error_message: nil)
      end
      let(:preprocess_result) do
        TypingTextPreprocessor::Result.new(success?: true, body: "整形済み本文", error_message: nil)
      end

      before do
        sign_in user
        allow(ArticleHtmlFetcher).to receive(:new).with(url).and_return(fetcher)
        allow(ArticleBodyExtractor).to receive(:new).with("<html></html>", url: url).and_return(extractor)
        allow(TypingTextPreprocessor).to receive(:new).with("あ" * 50).and_return(preprocessor)
        allow(fetcher).to receive(:call).and_return(fetch_result)
        allow(extractor).to receive(:call).and_return(extract_result)
        allow(preprocessor).to receive(:call).and_return(preprocess_result)
      end

      it "取得・抽出・前処理した記事を保存する" do
        expect {
          post articles_path, params: { url: url, category: "english" }
        }.to change(Article, :count).by(1)

        article = Article.last
        expect(article).to have_attributes(
          user: user,
          url: url,
          title: "取得記事",
          body: "整形済み本文",
          category: "english"
        )
        expect(response).to redirect_to(typing_path(article_id: article.id))
      end

      it "取得に失敗した場合は保存しない" do
        allow(fetcher).to receive(:call).and_return(
          ArticleHtmlFetcher::Result.new(success?: false, html: nil, error_message: "接続に失敗しました")
        )

        expect {
          post articles_path, params: { url: url }
        }.not_to change(Article, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /articles/fetch" do
    let(:fetcher) { instance_double(ArticleHtmlFetcher) }
    let(:extractor) { instance_double(ArticleBodyExtractor) }
    let(:preprocessor) { instance_double(TypingTextPreprocessor) }
    let(:fetch_result) do
      ArticleHtmlFetcher::Result.new(success?: true, html: "<html></html>", error_message: nil)
    end
    let(:extract_result) do
      ArticleBodyExtractor::Result.new(success?: true, body: "あ" * 50, title: "取得記事", error_message: nil)
    end
    let(:preprocess_result) do
      TypingTextPreprocessor::Result.new(success?: true, body: "整形済み本文", error_message: nil)
    end

    before do
      allow(ArticleHtmlFetcher).to receive(:new).with(url).and_return(fetcher)
      allow(ArticleBodyExtractor).to receive(:new).with("<html></html>", url: url).and_return(extractor)
      allow(TypingTextPreprocessor).to receive(:new).with("あ" * 50).and_return(preprocessor)
      allow(fetcher).to receive(:call).and_return(fetch_result)
      allow(extractor).to receive(:call).and_return(extract_result)
      allow(preprocessor).to receive(:call).and_return(preprocess_result)
    end

    it "整形済み本文とタイトルをJSONで返す" do
      post articles_fetch_path, params: { url: url }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to eq("body" => "整形済み本文", "title" => "取得記事")
    end

    it "取得失敗時はエラーを返す" do
      allow(fetcher).to receive(:call).and_return(
        ArticleHtmlFetcher::Result.new(success?: false, html: nil, error_message: "接続に失敗しました")
      )

      post articles_fetch_path, params: { url: url }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "接続に失敗しました")
    end

    it "抽出失敗時はエラーを返す" do
      allow(extractor).to receive(:call).and_return(
        ArticleBodyExtractor::Result.new(success?: false, body: nil, title: nil, error_message: "本文が見つかりませんでした")
      )

      post articles_fetch_path, params: { url: url }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "本文が見つかりませんでした")
    end

    it "前処理失敗時はエラーを返す" do
      allow(preprocessor).to receive(:call).and_return(
        TypingTextPreprocessor::Result.new(success?: false, body: nil, error_message: "テキストが短すぎます")
      )

      post articles_fetch_path, params: { url: url }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "テキストが短すぎます")
    end
  end

  describe "GET /articles/:id と GET /articles/:id/edit" do
    let(:article) { create(:article, user: user, title: "自分の記事") }

    it "未ログインでは記事を表示できない" do
      get article_path(article)

      expect(response).to redirect_to(new_user_session_path)
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "自分の記事を表示・編集できる" do
        get article_path(article)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("自分の記事")

        get edit_article_path(article)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("自分の記事")
      end

      it "他ユーザーの記事を表示・編集できない" do
        other_article = create(:article, user: create(:user))

        get article_path(other_article)
        expect(response).to redirect_to(root_path)

        get edit_article_path(other_article)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /articles/:id" do
    before { sign_in user }

    it "自分の記事のタイトル・本文・カテゴリ・タグを更新できる" do
      article = create(:article, user: user, title: "更新前", category: "tech")

      patch article_path(article), params: {
        title: "更新後",
        body: "あ" * 50,
        category: "english",
        tag_names: "Ruby, RSpec"
      }

      expect(response).to redirect_to(articles_path)
      expect(article.reload).to have_attributes(
        title: "更新後",
        body: "あ" * 50,
        category: "english"
      )
      expect(article.tags.pluck(:name)).to match_array([ "Ruby", "RSpec" ])
    end

    it "不正な本文では更新せず422を返す" do
      article = create(:article, user: user, title: "更新前")

      patch article_path(article), params: { title: "更新後", body: "あ" * 49 }

      expect(response).to have_http_status(:unprocessable_content)
      expect(article.reload.title).to eq("更新前")
    end

    it "他ユーザーの記事は更新できない" do
      article = create(:article, user: create(:user), title: "他人の記事")

      patch article_path(article), params: { title: "不正な更新" }

      expect(response).to redirect_to(root_path)
      expect(article.reload.title).to eq("他人の記事")
    end
  end

  describe "POST /articles/:id/favorite" do
    before { sign_in user }

    it "自分の記事のお気に入りを追加・解除できる" do
      article = create(:article, user: user)

      expect {
        post favorite_article_path(article), as: :turbo_stream
      }.to change(Favorite, :count).by(1)
      expect(response.body).to include("お気に入り済み")

      expect {
        post favorite_article_path(article), as: :turbo_stream
      }.to change(Favorite, :count).by(-1)
      expect(response.body).to include("お気に入り")
    end

    it "他ユーザーの記事はお気に入りにできない" do
      article = create(:article, user: create(:user))

      expect {
        post favorite_article_path(article), as: :turbo_stream
      }.not_to change(Favorite, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /articles の絞り込み" do
    before { sign_in user }

    it "カテゴリ・タグ・お気に入りで自分の記事だけを絞り込める" do
      target = create(:article, user: user, title: "対象記事", category: "tech")
      target.tags << Tag.create!(name: "Rails")
      current_user_other = create(:article, user: user, title: "別記事", category: "english")
      other_user_article = create(:article, user: create(:user), title: "他人の記事", category: "tech")
      Favorite.create!(user: user, article: target)

      get articles_path, params: { category: "tech", tag: "Rails", favorites_only: "true" }

      expect(response.body).to include(target.title)
      expect(response.body).not_to include(current_user_other.title)
      expect(response.body).not_to include(other_user_article.title)
    end
  end
end
