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

  describe "#save" do
    let(:url)       { "https://example.com/article" }
    let(:user)      { create(:user) }
    let(:tag_names) { nil }

    subject(:form) { described_class.new(url: url, user: user, tag_names: tag_names) }

    let(:fetcher)      { instance_double(ArticleHtmlFetcher) }
    let(:extractor)    { instance_double(ArticleBodyExtractor) }
    let(:preprocessor) { instance_double(TypingTextPreprocessor) }

    let(:fetch_result) do
      ArticleHtmlFetcher::Result.new(success?: true, html: "<html></html>", error_message: nil)
    end
    let(:extract_result) do
      ArticleBodyExtractor::Result.new(success?: true, body: "a" * 50, title: "テスト", error_message: nil)
    end
    let(:preprocess_result) do
      TypingTextPreprocessor::Result.new(success?: true, body: "a" * 50, error_message: nil)
    end

    before do
      allow(ArticleHtmlFetcher).to receive(:new).and_return(fetcher)
      allow(ArticleBodyExtractor).to receive(:new).and_return(extractor)
      allow(TypingTextPreprocessor).to receive(:new).and_return(preprocessor)
      allow(fetcher).to receive(:call).and_return(fetch_result)
      allow(extractor).to receive(:call).and_return(extract_result)
      allow(preprocessor).to receive(:call).and_return(preprocess_result)
    end

    context "既存記事がある場合" do
      let!(:existing_article) { create(:article, url: url, user: user) }

      it "外部フェッチを行わない" do
        expect(ArticleHtmlFetcher).not_to receive(:new)
        form.save
      end

      it "trueを返す" do
        expect(form.save).to be true
      end

      it "既存記事を返す" do
        form.save
        expect(form.article).to eq(existing_article)
      end

      it "Articleが新規作成されない" do
        expect { form.save }.not_to change(Article, :count)
      end
    end

    context "新規URLの場合" do
      it "trueを返す" do
        expect(form.save).to be true
      end

      it "Articleが1件作成される" do
        expect { form.save }.to change(Article, :count).by(1)
      end
    end

    context "外部フェッチが失敗した場合" do
      let(:fetch_result) do
        ArticleHtmlFetcher::Result.new(success?: false, html: nil, error_message: "接続に失敗しました")
      end

      it "falseを返す" do
        expect(form.save).to be false
      end

      it "エラーメッセージがセットされる" do
        form.save
        expect(form.errors[:base]).to include("接続に失敗しました")
      end
    end

    context "tag_namesを渡した場合" do
      let(:tag_names) { "Rails, Ruby" }

      it "タグが記事に紐づく" do
        form.save
        expect(form.article.tags.map(&:name)).to match_array([ "Rails", "Ruby" ])
      end
    end

    context "tag_namesが空文字の場合" do
      let(:tag_names) { "" }

      it "タグなしで保存される" do
        form.save
        expect(form.article.tags).to be_empty
      end
    end
  end
end
