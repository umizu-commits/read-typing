class ArticlesController < ApplicationController
  def create
    url = params[:url]

    if url.blank?
      redirect_to root_path, alert: "URLを入力してください"
      return
    end

    begin
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        redirect_to root_path, alert: "正しいURL形式で入力してください（例：https://example.com）"
        return
      end
    rescue URI::InvalidURIError
      redirect_to root_path, alert: "正しいURL形式で入力してください（例：https://example.com）"
      return
    end

    # HTML 取得
    fetch_result = ArticleHtmlFetcher.new(url).call
    unless fetch_result.success?
      redirect_to root_path, alert: fetch_result.error_message
      return
    end

    # 本文抽出
    extract_result = ArticleBodyExtractor.new(fetch_result.html).call
    unless extract_result.success?
      redirect_to root_path, alert: extract_result.error_message
      return
    end

    # 前処理
    preprocess_result = TypingTextPreprocessor.new(extract_result.body).call
    unless preprocess_result.success?
      redirect_to root_path, alert: preprocess_result.error_message
      return
    end

    # DB保存（同URL同ユーザー時は既存を再利用 / レース時は find_by に fallback）
    begin
      article = Article.find_or_create_by!(url: url, user_id: current_user&.id) do |a|
        a.body = preprocess_result.body
      end
    rescue ActiveRecord::RecordNotUnique
      article = Article.find_by!(url: url, user_id: current_user&.id)
    end

    redirect_to typing_path(article_id: article.id)
  end
end
