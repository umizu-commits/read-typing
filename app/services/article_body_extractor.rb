require "nokogiri"

class ArticleBodyExtractor
  # 本文として不要な要素（構造・非テキスト・インタラクティブ）
  UNWANTED_SELECTORS = "nav, header, footer, aside, script, style, noscript, form, button, input, pre, code".freeze
  CONTENT_SELECTORS = "p, h1, h2, h3, h4, h5, h6, li, blockquote".freeze
  MIN_BODY_LENGTH = 50
  MAX_TITLE_LENGTH = 255

  # ドメインごとのサイト名サフィックスパターン（末尾マッチ）
  SITE_SUFFIX_PATTERNS = {
    "qiita.com"       => /\s*-\s*Qiita\z/,
    "zenn.dev"        => /\s*\|\s*Zenn\z/,
    "note.com"        => /\s*\|\s*note\z/,
    "medium.com"      => /\s*[-|]\s*Medium\z/i,
    "dev.to"          => /\s*[-|]\s*DEV Community\z/i,
    "speakerdeck.com" => /\s*[-|]\s*Speaker Deck\z/i
  }.freeze

  Result = Struct.new(:success?, :body, :title, :error_message, keyword_init: true)

  def initialize(html, url: nil)
    @html = html
    @url  = url
  end

  def call
    doc = Nokogiri::HTML(@html)
    title = extract_title(doc)
    main_node = doc.at_css("article") || doc.at_css("main") || doc.at_css("body")
    return error_result("本文が見つかりませんでした") if main_node.nil?

    # 不要要素の削除
    main_node.css(UNWANTED_SELECTORS).remove

    # コンテンツ要素からテキスト抽出
    text_parts = main_node.css(CONTENT_SELECTORS).map { |el| el.text.strip }
    text_parts.reject!(&:empty?)
    body_text = text_parts.join("\n\n")

    # ホワイトスペース正規化
    body_text = body_text.gsub(/[ \t]+/, " ")
    body_text = body_text.gsub(/\n{3,}/, "\n\n")
    body_text = body_text.strip

    return error_result("本文が見つかりませんでした") if body_text.empty?
    return error_result("本文が短すぎます") if body_text.length < MIN_BODY_LENGTH

    success_result(body_text, title)
  end

  private

  def success_result(body, title)
    Result.new(success?: true, body: body, title: title, error_message: nil)
  end

  def error_result(message)
    Result.new(success?: false, body: nil, error_message: message)
  end

  def extract_title(doc)
    title = doc.at_css('meta[property="og:title"]')&.attr("content")&.strip
    title = doc.at_css("title")&.text&.strip if title.blank?
    return nil if title.blank?
    title = strip_site_suffix(title)
    title.length > MAX_TITLE_LENGTH ? title[0, MAX_TITLE_LENGTH] : title
  end

  def strip_site_suffix(title)
    return title if @url.blank?
    host = URI.parse(@url).hostname.to_s.downcase.delete_prefix("www.")
    pattern = SITE_SUFFIX_PATTERNS.find { |domain, _| host == domain || host.end_with?(".#{domain}") }&.last
    return title if pattern.nil?
    title.sub(pattern, "").strip
  rescue URI::InvalidURIError
    title
  end
end
