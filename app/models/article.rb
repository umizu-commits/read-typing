class Article < ApplicationRecord
  # 未ログインユーザーが作成した Article レコードの保持期間（経過後に削除対象）
  ANONYMOUS_EXPIRES_IN = 7.days

  belongs_to :user, optional: true
  has_many :typing_results, dependent: :nullify
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  enum :source_type, { url: "url", text: "text" }
  enum :category, { tech: "tech", english: "english", other: "other" }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "は正しいURL形式で入力してください" }, if: :url?
  validates :body, presence: true

  before_validation :set_expires_at_for_anonymous, on: :create

  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at < ?", Time.current) }

  scope :search_by_keyword, ->(keyword) {
    where("title ILIKE :q OR url ILIKE :q", q: "%#{sanitize_sql_like(keyword)}%")
  }

  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_tag, ->(tag_name) {
    joins(:tags).where(tags: { name: tag_name })
  }

  SORT_OPTIONS = {
    "newest" => { created_at: :desc },
    "oldest" => { created_at: :asc },
    "title_asc" => { title: :asc },
    "title_desc" => { title: :desc }
  }.freeze

  SORT_LABELS = {
    "newest"     => "新しい順",
    "oldest"     => "古い順",
    "title_asc"  => "タイトル昇順",
    "title_desc" => "タイトル降順"
  }.freeze

  CATEGORIES = {
    "tech"    => "技術記事",
    "english" => "英語記事",
    "other"   => "その他"
  }.freeze

  scope :sorted_by, ->(sort_key) {
    order(SORT_OPTIONS.fetch(sort_key, SORT_OPTIONS["newest"]))
  }

  def self.cleanup_expired!
    expired.destroy_all
  end

  private

  def set_expires_at_for_anonymous
    self.expires_at = ANONYMOUS_EXPIRES_IN.from_now if user_id.nil? && expires_at.nil?
  end
end
