class Achievement
  DEFINITIONS = {
    "first_typing"  => { name: "はじめの一歩",     description: "初めてタイピング練習を完了",      icon: :star },
    "first_article" => { name: "コレクター",        description: "初めて記事を保存",                icon: :bookmark },
    "typing_10"     => { name: "練習熱心",          description: "タイピング10回完了",              icon: :bolt },
    "typing_100"    => { name: "100本ノック",       description: "タイピング100回完了",             icon: :fire },
    "typing_1000"   => { name: "タイピングマスター", description: "タイピング1000回完了",            icon: :trophy },
    "chars_10000"   => { name: "1万字突破",         description: "累計正解文字数10,000字",          icon: :document },
    "chars_100000"  => { name: "10万字の壁",        description: "累計正解文字数100,000字",         icon: :stack },
    "time_1hour"    => { name: "1時間の修行",       description: "累計練習時間1時間",               icon: :clock },
    "time_10hours"  => { name: "10時間の道",        description: "累計練習時間10時間",              icon: :hourglass },
    "cpm_100"       => { name: "スピードスター",     description: "CPM 100以上を記録",              icon: :speed },
    "cpm_200"       => { name: "ハイスピード",      description: "CPM 200以上を記録",              icon: :rocket },
    "cpm_300"       => { name: "超高速タイピスト",   description: "CPM 300以上を記録",              icon: :zap },
    "accuracy_100"  => { name: "パーフェクト",      description: "正答率100%を記録",               icon: :check_circle },
    "streak_3"      => { name: "3日連続",           description: "3日連続でタイピング練習",         icon: :calendar },
    "streak_7"      => { name: "週間修行",          description: "7日連続でタイピング練習",         icon: :calendar },
    "streak_30"     => { name: "1ヶ月連続",         description: "30日連続でタイピング練習",        icon: :calendar },
    "sns_share"     => { name: "情報発信者",        description: "タイピング結果をSNSで共有",       icon: :share }
  }.freeze

  def self.find(key)
    DEFINITIONS[key.to_s]
  end
end
