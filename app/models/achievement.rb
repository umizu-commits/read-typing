class Achievement
  DEFINITIONS = {
    "first_typing"  => { name: "はじめの一歩",     description: "初めてタイピング練習を完了",      icon: :star,         contexts: [ :typing_saved ] },
    "first_article" => { name: "コレクター",        description: "初めて記事を保存",                icon: :bookmark,     contexts: [ :article_saved ] },
    "typing_10"     => { name: "練習熱心",          description: "タイピング10回完了",              icon: :bolt,         contexts: [ :typing_saved ] },
    "typing_100"    => { name: "100本ノック",       description: "タイピング100回完了",             icon: :fire,         contexts: [ :typing_saved ] },
    "typing_1000"   => { name: "タイピングマスター", description: "タイピング1000回完了",            icon: :trophy,       contexts: [ :typing_saved ] },
    "chars_10000"   => { name: "1万字突破",         description: "累計正解文字数10,000字",          icon: :document,     contexts: [ :typing_saved ] },
    "chars_100000"  => { name: "10万字の壁",        description: "累計正解文字数100,000字",         icon: :stack,        contexts: [ :typing_saved ] },
    "time_1hour"    => { name: "1時間の修行",       description: "累計練習時間1時間",               icon: :clock,        contexts: [ :typing_saved ] },
    "time_10hours"  => { name: "10時間の道",        description: "累計練習時間10時間",              icon: :hourglass,    contexts: [ :typing_saved ] },
    "cpm_100"       => { name: "スピードスター",     description: "CPM 100以上を記録",              icon: :speed,        contexts: [ :typing_saved ] },
    "cpm_200"       => { name: "ハイスピード",      description: "CPM 200以上を記録",              icon: :rocket,       contexts: [ :typing_saved ] },
    "cpm_300"       => { name: "超高速タイピスト",   description: "CPM 300以上を記録",              icon: :zap,          contexts: [ :typing_saved ] },
    "accuracy_100"  => { name: "パーフェクト",      description: "正答率100%を記録",               icon: :check_circle, contexts: [ :typing_saved ] },
    "streak_3"      => { name: "3日連続",           description: "3日連続でタイピング練習",         icon: :calendar,     contexts: [ :typing_saved ] },
    "streak_7"      => { name: "週間修行",          description: "7日連続でタイピング練習",         icon: :calendar,     contexts: [ :typing_saved ] },
    "streak_30"     => { name: "1ヶ月連続",         description: "30日連続でタイピング練習",        icon: :calendar,     contexts: [ :typing_saved ] },
    "sns_share"     => { name: "情報発信者",        description: "タイピング結果をSNSで共有",       icon: :share,        contexts: [ :sns_shared ] }
  }.freeze

  def self.find(key)
    DEFINITIONS[key.to_s]
  end

  def self.keys_for(context)
    DEFINITIONS.filter_map do |key, definition|
      key if definition[:contexts].include?(context)
    end
  end
end
