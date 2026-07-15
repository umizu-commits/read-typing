require "rails_helper"

RSpec.describe UserAchievement, type: :model do
  let(:user) { create(:user) }

  it "定義済みの実績キーと達成日時があれば有効" do
    achievement = described_class.new(
      user: user,
      achievement_key: "first_typing",
      achieved_at: Time.current
    )

    expect(achievement).to be_valid
  end

  it "未定義の実績キーと達成日時なしは無効" do
    expect(described_class.new(user: user, achievement_key: "unknown", achieved_at: Time.current)).not_to be_valid
    expect(described_class.new(user: user, achievement_key: "first_typing")).not_to be_valid
  end

  it "同一ユーザーに同じ実績キーを重複付与できない" do
    described_class.create!(user: user, achievement_key: "first_typing", achieved_at: Time.current)
    duplicate = described_class.new(user: user, achievement_key: "first_typing", achieved_at: Time.current)

    expect(duplicate).not_to be_valid
  end
end
