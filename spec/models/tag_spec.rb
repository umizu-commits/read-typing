require "rails_helper"

RSpec.describe Tag, type: :model do
  it "20文字以内の名前なら有効" do
    expect(described_class.new(name: "a" * 20)).to be_valid
  end

  it "名前が空または21文字以上なら無効" do
    expect(described_class.new(name: "")).not_to be_valid
    expect(described_class.new(name: "a" * 21)).not_to be_valid
  end

  it "同じ名前を重複して作成できない" do
    described_class.create!(name: "Rails")

    expect(described_class.new(name: "Rails")).not_to be_valid
  end
end
