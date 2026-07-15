class ArticleEditForm
  include ActiveModel::Model
  include TagsAttachable

  attr_accessor :article, :title, :body, :category, :tag_names

  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :body, length: { minimum: 50, maximum: 10_000 }, allow_blank: true
  validates :category, inclusion: { in: Article::CATEGORIES.keys }, allow_blank: true

  def initialize(article:, params: {})
    @article = article
    super(params)
  end

  def update
    return false unless valid?

    processed_body = if body.present?
      preprocess_result = TypingTextPreprocessor.new(body).call
      unless preprocess_result.success?
        errors.add(:base, preprocess_result.error_message)
        return false
      end
      preprocess_result.body
    end

    Article.transaction do
      article.body = processed_body if processed_body
      article.title = title.presence
      article.category = category
      article.save!
      attach_tags(article, clear_blank: true)
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    copy_record_errors(error.record)
    false
  end
end
