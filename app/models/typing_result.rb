class TypingResult < ApplicationRecord
  belongs_to :user
  belongs_to :article, optional: true

  validates :wpm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 400 } # 人間の限界WPMを大幅に超える値を弾く
  validates :cpm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2000 } # 人間の限界CPMを大幅に超える値を弾く（WPM世界記録は300前後）
  validates :accuracy, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 } # 正答率は100％より高くならない
  validates :miss_count, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100_000 }  # 記事の最大文字数の10倍程度
  validates :elapsed_time, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 86400 } # 24時間
  validates :article_text, presence: true, length: { maximum: 10_000 }
  validates :article_title, length: { maximum: 255 }, allow_blank: true
  validate :article_must_belong_to_user
  validate :correct_count_within_article_text_length

  scope :recent, -> { order(created_at: :desc) }

  private

  def article_must_belong_to_user
    return if article_id.blank?
    return if article.present? && article.user_id == user_id

    errors.add(:article, "は自分が保存した記事を指定してください")
  end

  def correct_count_within_article_text_length
    return if correct_count.blank? || article_text.blank?
    return if correct_count.between?(0, article_text.length)

    errors.add(:correct_count, "は本文の文字数以内で入力してください")
  end
end
