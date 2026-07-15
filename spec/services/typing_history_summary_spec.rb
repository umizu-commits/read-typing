require "rails_helper"

RSpec.describe TypingHistorySummary do
  let(:user) { create(:user) }
  let(:now) { Time.zone.local(2026, 7, 15, 12, 0, 0) }
  let(:today) { now.to_date }
  let(:period) { "30d" }
  let(:summary) do
    described_class.new(
      typing_results: TypingResult.where(user: user),
      period: period,
      now: now,
      today: today
    )
  end

  describe "比較用の集計" do
    it "最新結果と前回結果の差分、および全件の集計値を返す" do
      create(
        :typing_result,
        user: user,
        cpm: 280.0,
        accuracy: 93.0,
        article_text: "a" * 800,
        correct_count: 800,
        elapsed_time: 100,
        miss_count: 4,
        created_at: now - 2.hours
      )
      latest_result = create(
        :typing_result,
        user: user,
        cpm: 320.0,
        accuracy: 97.0,
        article_text: "a" * 1_200,
        correct_count: 1_200,
        elapsed_time: 200,
        miss_count: 2,
        created_at: now - 1.hour
      )

      expect(summary).to be_any_results
      expect(summary.latest_result).to eq(latest_result)
      expect(summary.cpm_difference).to eq(40.0)
      expect(summary.accuracy_difference).to eq(4.0)
      expect(summary.total_correct_count).to eq(2_000)
      expect(summary.total_elapsed_time).to eq(300)
      expect(summary.total_sessions).to eq(2)
      expect(summary.average_miss_count).to eq(3.0)
    end

    it "結果が1件だけの場合は前回比を返さない" do
      create(:typing_result, user: user, created_at: now)

      expect(summary.cpm_difference).to be_nil
      expect(summary.accuracy_difference).to be_nil
    end
  end

  describe "グラフ用データ" do
    before do
      create(:typing_result, user: user, article_title: "直近7日", cpm: 100.0, created_at: now - 6.days)
      create(:typing_result, user: user, article_title: "直近30日", cpm: 200.0, created_at: now - 29.days)
      create(:typing_result, user: user, article_title: "期間外", cpm: 300.0, created_at: now - 31.days)
    end

    it "選択した期間の結果を古い順に返す" do
      expect(summary.chart_data.map { |point| point[:title] }).to eq([ "直近30日", "直近7日" ])
      expect(summary.chart_data.map { |point| point[:is_best] }).to eq([ true, false ])
    end

    context "period=7dの場合" do
      let(:period) { "7d" }

      it "直近7日間の結果だけを返す" do
        expect(summary.chart_data.map { |point| point[:title] }).to eq([ "直近7日" ])
      end
    end

    context "不正なperiodの場合" do
      let(:period) { "invalid" }

      it "30日をデフォルトにする" do
        expect(summary.current_period).to eq("30d")
        expect(summary.chart_data.map { |point| point[:title] }).to eq([ "直近30日", "直近7日" ])
      end
    end
  end

  describe "ヒートマップ用データ" do
    it "当日までの練習回数だけを日別に集計する" do
      create(:typing_result, user: user, created_at: now - 1.day)
      2.times { create(:typing_result, user: user, created_at: now) }
      create(:typing_result, user: user, created_at: now + 1.day)

      yesterday = summary.heatmap_days.find { |day| day[:date] == today - 1.day }
      current_day = summary.heatmap_days.find { |day| day[:date] == today }
      tomorrow = summary.heatmap_days.find { |day| day[:date] == today + 1.day }

      expect(yesterday).to include(count: 1, in_range: true, in_year: true)
      expect(current_day).to include(count: 2, in_range: true, in_year: true)
      expect(tomorrow).to include(count: 0, in_range: false, in_year: true)
      expect(summary.heatmap_active_days).to eq(2)
      expect(summary.heatmap_total_count).to eq(3)
    end
  end
end
