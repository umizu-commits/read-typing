class ArticleForm
  include ActiveModel::Model
  include TagsAttachable

  attr_accessor :url, :user, :category, :tag_names

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "は正しいURL形式で入力してください" }
  validate :url_must_use_hostname
  validates :category, inclusion: { in: Article::CATEGORIES.keys }, allow_blank: true

  def save
    return false unless valid?

    # 既存記事があれば外部フェッチをスキップして再利用する
    existing = Article.find_by(url: url, user_id: user&.id)
    if existing
      @article = existing
      attach_tags(@article)
      return true
    end

    fetch_result = ArticleHtmlFetcher.new(url).call
    unless fetch_result.success?
      errors.add(:base, fetch_result.error_message)
      return false
    end

    extract_result = ArticleBodyExtractor.new(fetch_result.html, url: url).call
    unless extract_result.success?
      errors.add(:base, extract_result.error_message)
      return false
    end

    preprocess_result = TypingTextPreprocessor.new(extract_result.body).call
    unless preprocess_result.success?
      errors.add(:base, preprocess_result.error_message)
      return false
    end

    # find_or_create_by! は SELECT→INSERT の2ステップのため、並行リクエスト時に
    # 両方が INSERT を試みて一意制約違反になることがある。その場合は既存レコードを取得する。
    begin
      @article = Article.find_or_create_by!(url: url, user_id: user&.id) do |a|
        a.body = preprocess_result.body
        a.title = extract_result.title
        a.category = category
      end
    rescue ActiveRecord::RecordNotUnique
      @article = Article.find_by!(url: url, user_id: user&.id)
    end
    attach_tags(@article)
    true
  end

  def article
    @article
  end

  private

  def url_must_use_hostname
    return if url.blank? # presence バリデーションに任せる
    host = URI.parse(url).hostname
    return if host.nil?

    IPAddr.new(host) # 例外が出なければ IP リテラル → エラー
    errors.add(:url, "にIPアドレスは使用できません")
  rescue IPAddr::InvalidAddressError
    nil # ドメイン名なので OK
  rescue URI::InvalidURIError
    nil # format バリデーションに任せる
  end
end
