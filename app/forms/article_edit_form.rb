class ArticleEditForm
  include ActiveModel::Model

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

    if body.present?
      preprocess_result = TypingTextPreprocessor.new(body).call
      unless preprocess_result.success?
        errors.add(:base, preprocess_result.error_message)
        return false
      end
      article.body = preprocess_result.body
    end

    article.title    = title.presence
    article.category = category

    return false unless article.save

    attach_tags
    true
  end

  private

  def attach_tags
    return if tag_names.nil?

    names = tag_names.split(",").map(&:strip).reject(&:blank?).uniq
    tags  = names.map { |name| Tag.find_or_create_by!(name: name) }
    article.tags = tags
  end
end
