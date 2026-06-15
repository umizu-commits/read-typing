require "faraday"
require "faraday/follow_redirects"

class ArticleHtmlFetcher
  Result = Struct.new(:success?, :html, :error_message, keyword_init: true)

  def initialize(url)
    @url = url
  end

  def call
    conn = Faraday.new do |f|
      f.response :follow_redirects, limit: 5
      f.options.open_timeout = 5
      f.options.timeout = 10
    end

    response = conn.get(@url)

    case response.status
    when 200..299
      success_result(response.body)
    when 404
      error_result("ページが見つかりませんでした")
    when 400..499
      error_result("ページにアクセスできませんでした")
    when 500..599
      error_result("サーバーエラーが発生しました")
    else
      error_result("予期しないエラーが発生しました")
    end

  rescue Faraday::ConnectionFailed
    error_result("接続に失敗しました")
  rescue Faraday::TimeoutError
    error_result("応答が遅すぎます")
  rescue Faraday::SSLError
    error_result("SSL通信に失敗しました")
  rescue Faraday::FollowRedirects::RedirectLimitReached
    error_result("リダイレクトが多すぎます")
  rescue Faraday::Error
    error_result("HTMLの取得に失敗しました")
  end

  private

  def success_result(html)
    Result.new(success?: true, html: html, error_message: nil)
  end

  def error_result(message)
    Result.new(success?: false, html: nil, error_message: message)
  end
end
