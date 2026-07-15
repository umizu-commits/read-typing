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
    existing_article = Article.find_by(url: url, user_id: user&.id)
    if existing_article
      return persist_article_with_tags { @article = existing_article }
    end

    content_result = ArticleContentFetcher.new(url).call
    unless content_result.success?
      errors.add(:base, content_result.error_message)
      return false
    end

    persist_article_with_tags do
      @article = find_or_create_article(content_result)
    end
  end

  def article
    @article
  end

  private

  def persist_article_with_tags
    Article.transaction do
      yield
      attach_tags(@article)
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    copy_record_errors(error.record)
    false
  end

  def find_or_create_article(content_result)
    # 一意制約違反をセーブポイント内で処理し、並行作成時は既存記事を再利用する。
    begin
      Article.transaction(requires_new: true) do
        Article.find_or_create_by!(url: url, user_id: user&.id) do |article|
          article.body = content_result.body
          article.title = content_result.title
          article.category = category
        end
      end
    rescue ActiveRecord::RecordNotUnique
      Article.find_by!(url: url, user_id: user&.id)
    rescue ActiveRecord::RecordInvalid => error
      raise unless uniqueness_conflict?(error.record, :url)

      Article.find_by!(url: url, user_id: user&.id)
    end
  end

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
