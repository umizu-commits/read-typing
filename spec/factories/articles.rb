FactoryBot.define do
  factory :article do
    association :user
    title { "テスト記事タイトル" }
    sequence(:url) { |n| "https://example.com/article/#{n}" }
    body { "テスト用の記事本文です。" }
  end
end
