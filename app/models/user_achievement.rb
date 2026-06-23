class UserAchievement < ApplicationRecord
  belongs_to :user

  validates :achievement_key, presence: true,
            inclusion: { in: Achievement::DEFINITIONS.keys }
  validates :achievement_key, uniqueness: { scope: :user_id }
  validates :achieved_at, presence: true
end
