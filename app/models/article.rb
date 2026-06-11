class Article < ApplicationRecord
  belongs_to :user
  has_many :typing_results, dependent: :nullify

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "は正しいURL形式で入力してください" }
  validates :body, presence: true
end
