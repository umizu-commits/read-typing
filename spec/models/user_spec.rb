require 'rails_helper'

RSpec.describe User, type: :model do
  describe "アソシエーション" do
    it "複数のタイピング結果を持てる" do
      user = create(:user)
      create(:typing_result, user: user)
      create(:typing_result, user: user)
      expect(user.typing_results.count).to eq 2
    end

    it "削除されるとタイピング結果も削除される" do
      user = create(:user)
      create(:typing_result, user: user)
      expect { user.destroy }.to change(TypingResult, :count).by(-1)
    end
  end

  describe "バリデーション" do
    it "email・passwordがあれば有効" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "emailがなければ無効" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "emailが重複していれば無効" do
      create(:user, email: "test@example.com")
      user = build(:user, email: "test@example.com")
      expect(user).not_to be_valid
    end

    it "passwordがなければ無効" do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
    end

    it "passwordが6文字未満であれば無効" do
      user = build(:user, password: "abc12")
      expect(user).not_to be_valid
    end
  end

  describe "メール確認" do
    it "Confirmableを有効にしている" do
      expect(described_class.devise_modules).to include(:confirmable)
    end
  end
end
