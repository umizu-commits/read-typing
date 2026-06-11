class TypingResult < ApplicationRecord
  belongs_to :user
  belongs_to :article, optional: true

  validates :wpm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 400 } # 人間の限界WPMを大幅に超える値を弾く
  validates :cpm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2000 } # 人間の限界CPMを大幅に超える値を弾く（WPM世界記録は300前後）
  validates :accuracy, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 } # 正答率は100％より高くならない
  validates :miss_count, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100_000 }  # 記事の最大文字数の10倍程度
  validates :elapsed_time, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 86400 } # 24時間
  validates :article_text, presence: true, length: { maximum: 10_000 }

  scope :recent, -> { order(created_at: :desc) }
end
