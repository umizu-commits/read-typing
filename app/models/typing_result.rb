class TypingResult < ApplicationRecord
  belongs_to :user

  validates :wpm, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cpm, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :accuracy, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :miss_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :elapsed_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :article_text, presence: true, length: { maximum: 10_000 }

  scope :recent, -> { order(created_at: :desc) }
end
