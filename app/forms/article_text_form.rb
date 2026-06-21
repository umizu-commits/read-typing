class ArticleTextForm
  include ActiveModel::Model

  attr_accessor :body, :title, :user

  # body の文字数バリデーション（前処理前の値に対して行う）
  validates :body, presence: true, length: { minimum: 50, maximum: 10_000 }
  validates :title, length: { maximum: 255 }, allow_blank: true

  def save
    return false unless valid?

    # TypingTextPreprocessor で本文を整形
    preprocess_result = TypingTextPreprocessor.new(body).call
    unless preprocess_result.success?
      errors.add(:base, preprocess_result.error_message)
      return false
    end

    # url なし・source_type: :text で新規作成
    @article = Article.create!(
      body: preprocess_result.body,
      title: title.presence,
      source_type: :text,
      user: user
    )
    true
  end

  def article
    @article
  end
end
