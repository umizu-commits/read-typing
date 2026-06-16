class TypingTextPreprocessor
  MIN_BODY_LENGTH = 50

  # データベース（Article モデル）に保存する設計を実装するまで一時的にCookieで保存するための制限
  MAX_BODY_LENGTH = 500
  
  Result = Struct.new(:success?, :body, :error_message, keyword_init: true)

  def initialize(text)
    @text = text
  end

  def call
    text = @text.dup

    # 不正UTF-8を安全化
    text = text.scrub("")

    # 改行コード統一
    text = text.gsub("\r\n", "\n")

    # 改行以外の制御文字を除去
    text = text.gsub(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/, "")

    # ゼロ幅・方向制御文字を除去
    text = text.gsub(/[\u200B-\u200F\u202A-\u202E\uFEFF]/, "")

    # 絵文字を除去
    text = text.gsub(/\p{Emoji_Presentation}/, "")
    
    # 全角スペース→半角、タブ→スペース
    text = text.gsub("\u3000", " ")
    text = text.gsub("\t", " ")

    # 空白・改行の圧縮
    # 改行以外の連続空白を1つに
    text = text.gsub(/[^\S\n]+/, " ")
    # 各行の前後空白除去
    text = text.split("\n").map(&:strip).join("\n")
    # 3つ以上の改行を2つに
    text = text.gsub(/\n{3,}/, "\n\n")
    # 全体の前後空白除去
    text = text.strip
    # 空・短すぎるチェック
    return error_result("テキストが短すぎます") if text.length < MIN_BODY_LENGTH

    # データベース（Article モデル）に保存する設計を実装するまで一時的にCookieで保存するための制限
    truncated = text[0, MAX_BODY_LENGTH]
    last_period = truncated.rindex("。")
    text = last_period ? truncated[0, last_period + 1] : truncated

    success_result(text)
  end

  private

  def success_result(body)
    Result.new(success?: true, body: body, error_message: nil)
  end

  def error_result(message)
    Result.new(success?: false, body: nil, error_message: message)
  end
end