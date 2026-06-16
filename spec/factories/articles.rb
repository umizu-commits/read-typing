FactoryBot.define do
  factory :article do
    title { "テスト記事タイトル" }
    sequence(:url) { |n| "https://example.com/article/#{n}" }
    body { "テスト用の記事本文です。" }
    user { nil }

    trait :with_user do
      association :user
    end
  end
end
