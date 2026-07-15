require "rails_helper"

RSpec.describe ArticleContentFetcher do
  subject(:result) { described_class.new(url).call }

  let(:url) { "https://example.com/articles/1" }
  let(:html_fetcher) { instance_double(ArticleHtmlFetcher) }
  let(:body_extractor) { instance_double(ArticleBodyExtractor) }
  let(:text_preprocessor) { instance_double(TypingTextPreprocessor) }
  let(:fetch_result) do
    ArticleHtmlFetcher::Result.new(success?: true, html: "<html></html>", error_message: nil)
  end
  let(:extract_result) do
    ArticleBodyExtractor::Result.new(success?: true, body: "本文" * 30, title: "取得記事", error_message: nil)
  end
  let(:preprocess_result) do
    TypingTextPreprocessor::Result.new(success?: true, body: "整形済み本文", error_message: nil)
  end

  before do
    allow(ArticleHtmlFetcher).to receive(:new).with(url).and_return(html_fetcher)
    allow(ArticleBodyExtractor).to receive(:new).with("<html></html>", url: url).and_return(body_extractor)
    allow(TypingTextPreprocessor).to receive(:new).with("本文" * 30).and_return(text_preprocessor)
    allow(html_fetcher).to receive(:call).and_return(fetch_result)
    allow(body_extractor).to receive(:call).and_return(extract_result)
    allow(text_preprocessor).to receive(:call).and_return(preprocess_result)
  end

  it "取得・抽出・前処理後の本文とタイトルを返す" do
    expect(result).to have_attributes(
      success?: true,
      body: "整形済み本文",
      title: "取得記事",
      error_message: nil
    )
  end

  context "HTML取得に失敗した場合" do
    let(:fetch_result) do
      ArticleHtmlFetcher::Result.new(success?: false, html: nil, error_message: "接続に失敗しました")
    end

    it "以降を実行せずにエラーを返す" do
      expect(ArticleBodyExtractor).not_to receive(:new)

      expect(result).to have_attributes(success?: false, error_message: "接続に失敗しました")
    end
  end

  context "本文抽出に失敗した場合" do
    let(:extract_result) do
      ArticleBodyExtractor::Result.new(success?: false, body: nil, title: nil, error_message: "本文が見つかりませんでした")
    end

    it "前処理を行わずにエラーを返す" do
      expect(TypingTextPreprocessor).not_to receive(:new)

      expect(result).to have_attributes(success?: false, error_message: "本文が見つかりませんでした")
    end
  end

  context "本文前処理に失敗した場合" do
    let(:preprocess_result) do
      TypingTextPreprocessor::Result.new(success?: false, body: nil, error_message: "テキストが短すぎます")
    end

    it "エラーを返す" do
      expect(result).to have_attributes(success?: false, error_message: "テキストが短すぎます")
    end
  end
end
