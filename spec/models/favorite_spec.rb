require "rails_helper"

RSpec.describe Favorite, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  it "ユーザーと記事を紐づけて保存できる" do
    favorite = described_class.new(user: user, article: article)

    expect(favorite).to be_valid
  end

  it "同じユーザーは同じ記事を重複してお気に入りにできない" do
    described_class.create!(user: user, article: article)
    duplicate = described_class.new(user: user, article: article)

    expect(duplicate).not_to be_valid
  end

  it "記事を削除するとお気に入りも削除される" do
    described_class.create!(user: user, article: article)

    expect {
      article.destroy
    }.to change(described_class, :count).by(-1)
  end
end
