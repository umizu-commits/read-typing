class ArticleForm
  include ActiveModel::Model

  attr_accessor :url, :user

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "は正しいURL形式で入力してください" }

  def save
    return false unless valid?

    fetch_result = ArticleHtmlFetcher.new(url).call
    unless fetch_result.success?
      errors.add(:base, fetch_result.error_message)
      return false
    end

    extract_result = ArticleBodyExtractor.new(fetch_result.html).call
    unless extract_result.success?
      errors.add(:base, extract_result.error_message)
      return false
    end

    preprocess_result = TypingTextPreprocessor.new(extract_result.body).call
    unless preprocess_result.success?
      errors.add(:base, preprocess_result.error_message)
      return false
    end

    begin
      @article = Article.find_or_create_by!(url: url, user_id: user&.id) do |a|
        a.body = preprocess_result.body
        a.title = extract_result.title
      end
    rescue ActiveRecord::RecordNotUnique
      @article = Article.find_by!(url: url, user_id: user&.id)
    end
    true
  end

  def article
    @article
  end
end
