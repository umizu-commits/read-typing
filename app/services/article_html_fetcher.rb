require "faraday"
require "faraday/follow_redirects"
require "resolv"
require "ipaddr"

class ArticleHtmlFetcher
  USER_AGENT = "ReadTyping/1.0 (+https://github.com/umizu-commits/read-typing)"
  MAX_BODY_SIZE = 5 * 1024 * 1024  # 5MB

  # SSRF 対策で拒否する IP 範囲（ループバック・プライベート・リンクローカルなど）。
  # safe_host? の判定で使用する。
  PRIVATE_IP_RANGES = [
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("0.0.0.0/8"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  # follow_redirects ミドルウェアの callback でリダイレクト先のホストが safe_host? を通過しなかったときに raise する。
  class UnsafeRedirectError < StandardError; end

  Result = Struct.new(:success?, :html, :error_message, keyword_init: true)

  def initialize(url)
    @url = url
  end

  def call
    return error_result("アクセスできないURLです") unless safe_host?(@url)

    conn = Faraday.new(headers: { "User-Agent" => USER_AGENT }) do |f|
      f.response :follow_redirects, limit: 5, callback: ->(env, _response) {
        raise UnsafeRedirectError unless safe_host?(env[:url].to_s)
      }
      f.options.open_timeout = 5
      f.options.timeout = 10
    end

    response = conn.get(@url)

    case response.status
    when 200..299
      if response.body.bytesize > MAX_BODY_SIZE
        error_result("ファイルサイズが大きすぎます")
      else
        content_type = response.headers["Content-Type"].to_s
        if content_type.start_with?("text/html")
          success_result(response.body)
        else
          error_result("HTMLではないため取得できません")
        end
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

  rescue UnsafeRedirectError
    # safe_host? チェックと同じメッセージにすることで、攻撃者に「直接 vs リダイレクト経由」を判別させない
    error_result("アクセスできないURLです")
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

  def safe_host?(url)
    uri = URI.parse(url)
    host = uri.hostname
    return false if host.nil?

    ips = host_to_ips(host)
    return false if ips.empty?

    # 一つのホストが複数 IP（IPv4 + IPv6 など）に解決される場合、
    # どれか一つでもプライベート範囲に含まれていれば SSRF のリスクがあるため、
    # 「すべての IP が安全範囲外」であることを要求する（防御側に倒す）。
    ips.all? do |ip|
      ip_addr = IPAddr.new(ip)
      # IPv4-mapped IPv6（例: ::ffff:127.0.0.1）は family が IPv6 になり、
      # IPv4 範囲（127.0.0.0/8 など）の include? とマッチしない。
      # native で IPv4 形式に正規化することで、範囲チェックを正しく機能させる。
      ip_addr = ip_addr.native if ip_addr.ipv4_mapped?
      PRIVATE_IP_RANGES.none? { |range| range.include?(ip_addr) }
    end
  rescue Resolv::ResolvError, URI::InvalidURIError, IPAddr::InvalidAddressError
    false
  end

  # ホスト文字列を IP 配列に変換する。
  # 入力が IP リテラル（127.0.0.1, ::1 など）の場合は Resolv が
  # Ruby のバージョン/環境によって空配列を返すことがあるため、
  # 先に IPAddr で解釈できるかを確認し、リテラルならそのまま返す。
  def host_to_ips(host)
    IPAddr.new(host)
    [ host ]
  rescue IPAddr::InvalidAddressError
    Resolv.getaddresses(host)
  end
end
