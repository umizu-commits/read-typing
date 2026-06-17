require "ssrf_filter"

class ArticleHtmlFetcher
  USER_AGENT = "ReadTyping/1.0 (+https://github.com/umizu-commits/read-typing)"
  MAX_BODY_SIZE = 5 * 1024 * 1024  # 5MB

  Result = Struct.new(:success?, :html, :error_message, keyword_init: true)
  BodyTooLargeError = Class.new(StandardError)

  def initialize(url)
    @url = url
  end

  def call
    buffer = +""  # ミュータブルな空文字列（+ はフリーズしない文字列を作る）
    
    response = SsrfFilter.get(
      @url,
      headers: { "User-Agent" => USER_AGENT },
      open_timeout: 5,
      read_timeout: 10,
      max_redirects: 5
    ) do |res|
      res.read_body do |chunk|
        buffer << chunk
        raise BodyTooLargeError if buffer.bytesize > MAX_BODY_SIZE
      end
    end

    case response.code.to_i
    when 200..299
      content_type = response["content-type"].to_s
      if content_type.start_with?("text/html")
        success_result(buffer)
      else
        error_result("HTMLではないため取得できません")
      end
    when 404
      error_result("ページが見つかりませんでした")
    when 400..499
      error_result("ページにアクセスできませんでした")
    when 500..599
      error_result("サーバーエラーが発生しました")
    else
      error_result("予期しないエラーが発生しました")
    end

  rescue BodyTooLargeError
    error_result("ファイルサイズが大きすぎます")
  rescue SsrfFilter::TooManyRedirects
    error_result("リダイレクトが多すぎます")
  rescue SocketError
    error_result("接続に失敗しました")
  rescue Net::OpenTimeout, Net::ReadTimeout
    error_result("応答が遅すぎます")
  rescue OpenSSL::SSL::SSLError
    error_result("SSL通信に失敗しました")
  rescue SsrfFilter::Error
    error_result("アクセスできないURLです")
  end

  private

  def success_result(html)
    Result.new(success?: true, html: html, error_message: nil)
  end

  def error_result(message)
    Result.new(success?: false, html: nil, error_message: message)
  end
end
