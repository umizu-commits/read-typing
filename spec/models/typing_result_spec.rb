require 'rails_helper'

RSpec.describe TypingResult, type: :model do
  describe "アソシエーション" do
    it "ユーザーに紐づいている" do
      typing_result = create(:typing_result)
      expect(typing_result.user).to be_present
    end

    it "ユーザーがいなければ無効" do
      typing_result = build(:typing_result, user: nil)
      expect(typing_result).not_to be_valid
    end
  end

  describe "バリデーション" do
    it "すべての属性が揃っていれば有効" do
      typing_result = build(:typing_result)
      expect(typing_result).to be_valid
    end

    it "wpmがなければ無効" do
      typing_result = build(:typing_result, wpm: nil)
      expect(typing_result).not_to be_valid
    end

    it "wpmが0未満であれば無効" do
      typing_result = build(:typing_result, wpm: -1)
      expect(typing_result).not_to be_valid
    end

    it "wpmが上限値なら有効" do
      typing_result = build(:typing_result, wpm: 400)
      expect(typing_result).to be_valid
    end

    it "wpmが上限値を超えると無効" do
      typing_result = build(:typing_result, wpm: 400.1)
      expect(typing_result).not_to be_valid
    end

    it "cpmがなければ無効" do
      typing_result = build(:typing_result, cpm: nil)
      expect(typing_result).not_to be_valid
    end

    it "cpmが0未満であれば無効" do
      typing_result = build(:typing_result, cpm: -1)
      expect(typing_result).not_to be_valid
    end

    it "cpmが上限値なら有効" do
      typing_result = build(:typing_result, cpm: 2000)
      expect(typing_result).to be_valid
    end

    it "cpmが上限値を超えると無効" do
      typing_result = build(:typing_result, cpm: 2000.1)
      expect(typing_result).not_to be_valid
    end

    it "accuracyがなければ無効" do
      typing_result = build(:typing_result, accuracy: nil)
      expect(typing_result).not_to be_valid
    end

    it "accuracyが0未満であれば無効" do
      typing_result = build(:typing_result, accuracy: -1)
      expect(typing_result).not_to be_valid
    end

    it "accuracyが上限値なら有効" do
      typing_result = build(:typing_result, accuracy: 100)
      expect(typing_result).to be_valid
    end

    it "accuracyが上限値を超えると無効" do
      typing_result = build(:typing_result, accuracy: 100.1)
      expect(typing_result).not_to be_valid
    end

    it "miss_countがなければ無効" do
      typing_result = build(:typing_result, miss_count: nil)
      expect(typing_result).not_to be_valid
    end

    it "miss_countが0未満であれば無効" do
      typing_result = build(:typing_result, miss_count: -1)
      expect(typing_result).not_to be_valid
    end

    it "miss_countが上限値なら有効" do
      typing_result = build(:typing_result, miss_count: 100_000)
      expect(typing_result).to be_valid
    end

    it "miss_countが上限値を超えると無効" do
      typing_result = build(:typing_result, miss_count: 100_001)
      expect(typing_result).not_to be_valid
    end

    it "elapsed_timeがなければ無効" do
      typing_result = build(:typing_result, elapsed_time: nil)
      expect(typing_result).not_to be_valid
    end

    it "elapsed_timeが0未満であれば無効" do
      typing_result = build(:typing_result, elapsed_time: -1)
      expect(typing_result).not_to be_valid
    end

    it "elapsed_timeが上限値なら有効" do
      typing_result = build(:typing_result, elapsed_time: 86_400)
      expect(typing_result).to be_valid
    end

    it "elapsed_timeが上限値を超えると無効" do
      typing_result = build(:typing_result, elapsed_time: 86_401)
      expect(typing_result).not_to be_valid
    end

    it "article_textがなければ無効" do
      typing_result = build(:typing_result, article_text: nil)
      expect(typing_result).not_to be_valid
    end

    it "article_textが空文字なら無効" do
      typing_result = build(:typing_result, article_text: "")
      expect(typing_result).not_to be_valid
    end

    it "article_textが10,000文字なら有効" do
      typing_result = build(:typing_result, article_text: "a" * 10_000)
      expect(typing_result).to be_valid
    end

    it "article_textが10,000文字を超えると無効" do
      typing_result = build(:typing_result, article_text: "a" * 10_001)
      expect(typing_result).not_to be_valid
    end

    it "article_titleが空文字なら有効" do
      typing_result = build(:typing_result, article_title: "")
      expect(typing_result).to be_valid
    end

    it "article_titleが255文字なら有効" do
      typing_result = build(:typing_result, article_title: "a" * 255)
      expect(typing_result).to be_valid
    end

    it "article_titleが255文字を超えると無効" do
      typing_result = build(:typing_result, article_title: "a" * 256)
      expect(typing_result).not_to be_valid
    end
  end

  describe "記事の所有者" do
    it "記事を指定しない場合は有効" do
      typing_result = build(:typing_result, article: nil)
      expect(typing_result).to be_valid
    end

    it "自分が保存した記事を指定した場合は有効" do
      user = create(:user)
      article = create(:article, user: user)
      typing_result = build(:typing_result, user: user, article: article)

      expect(typing_result).to be_valid
    end

    it "他のユーザーが保存した記事を指定した場合は無効" do
      owner = create(:user)
      other_user = create(:user)
      article = create(:article, user: owner)
      typing_result = build(:typing_result, user: other_user, article: article)

      expect(typing_result).not_to be_valid
    end

    it "存在しない記事を指定した場合は無効" do
      typing_result = build(:typing_result, user: create(:user), article_id: -1)

      expect(typing_result).not_to be_valid
    end
  end

  describe ".recent" do
    it "作成日時の降順で返す" do
      older_result = create(:typing_result, created_at: 2.days.ago)
      newer_result = create(:typing_result, created_at: 1.day.ago)

      results = described_class.where(id: [ older_result.id, newer_result.id ]).recent

      expect(results.pluck(:id)).to eq([ newer_result.id, older_result.id ])
    end
  end
end
