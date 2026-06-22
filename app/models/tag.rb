class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 20 }
end