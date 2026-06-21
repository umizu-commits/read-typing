class Article < ApplicationRecord
  # 未ログインユーザーが作成した Article レコードの保持期間（経過後に削除対象）
  ANONYMOUS_EXPIRES_IN = 7.days

  belongs_to :user, optional: true
  has_many :typing_results, dependent: :nullify

  enum :source_type, { url: "url", text: "text" }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "は正しいURL形式で入力してください" }, if: :url?
  validates :body, presence: true

  before_validation :set_expires_at_for_anonymous, on: :create

  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at < ?", Time.current) }

  def self.cleanup_expired!
    expired.destroy_all
  end

  private

  def set_expires_at_for_anonymous
    self.expires_at = ANONYMOUS_EXPIRES_IN.from_now if user_id.nil? && expires_at.nil?
  end
end
