require "nokogiri"

class ArticleBodyExtractor
  # 本文として不要な要素（構造・非テキスト・インタラクティブ）
  UNWANTED_SELECTORS = "nav, header, footer, aside, script, style, noscript, form, button, input, pre, code".freeze
  CONTENT_SELECTORS = "p, h1, h2, h3, h4, h5, h6, li, blockquote".freeze
  MIN_BODY_LENGTH = 50

  Result = Struct.new(:success?, :body, :error_message, keyword_init: true)

  def initialize(html)
    @html = html
  end

  def call
    doc = Nokogiri::HTML(@html)
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

    success_result(body_text)
  end

  private

  def success_result(body)
    Result.new(success?: true, body: body, error_message: nil)
  end

  def error_result(message)
    Result.new(success?: false, body: nil, error_message: message)
  end
end
