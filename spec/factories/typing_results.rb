FactoryBot.define do
  factory :typing_result do
    association :user
    wpm { 50.0 }
    cpm { 300.0 }
    accuracy { 95.0 }
    miss_count { 3 }
    elapsed_time { 120 }
    article_text { "これはテスト用の記事テキストです。" }
  end
end
