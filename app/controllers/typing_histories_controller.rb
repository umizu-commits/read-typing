class TypingHistoriesController < ApplicationController
  before_action :authenticate_user!
  def index
    authorize TypingResult, :index?
    # 現在のユーザーの結果だけを返す
    @all_typing_results = policy_scope(TypingResult)
    # ページネーション適用（テーブル表示用）
    @typing_results = @all_typing_results.recent.page(params[:page]).per(10)
    # タブ状態（summary or list）
    @active_tab = params[:tab] == "list" ? "list" : "summary"

    # 前回比計算（最新と1つ前の結果を取得）
    recent_two = @all_typing_results.order(created_at: :desc).limit(2).to_a
    @latest_result = recent_two[0]
    @prev_result = recent_two[1]
    if @latest_result && @prev_result
      @cpm_diff = @latest_result.cpm - @prev_result.cpm
      @accuracy_diff = @latest_result.accuracy - @prev_result.accuracy
    end

    # 期間フィルタ（7d / 30d / all、デフォルトは 30d）
    @current_period = params[:period].presence_in(%w[7d 30d all]) || "30d"

    # グラフ用データをインラインで生成（別途AJAXリクエスト不要）
    chart_scope = @all_typing_results.order(created_at: :desc)
    chart_scope = chart_scope.where(created_at: 7.days.ago..) if @current_period == "7d"
    chart_scope = chart_scope.where(created_at: 30.days.ago..) if @current_period == "30d"
    chart_results = chart_scope.limit(100).includes(:article).to_a.reverse
    best_cpm = chart_results.map(&:cpm).max
    @chart_data = chart_results.map do |r|
      title = r.article_title.presence || r.article&.title.presence
      {
        label: r.created_at.strftime("%-m/%-d"),
        full_label: r.created_at.strftime("%Y/%m/%d %H:%M"),
        cpm: r.cpm,
        accuracy: r.accuracy,
        title: title,
        is_best: chart_results.size > 1 && r.cpm == best_cpm
      }
    end

    # 継続ヒートマップ用データ（今年1月1日〜12月31日、起点を日曜・終点を土曜にパディングして矩形化）
    today = Date.current
    target_start = Date.new(today.year, 1, 1)
    target_end = Date.new(today.year, 12, 31)
    padded_start = target_start - target_start.wday
    padded_end = target_end + (6 - target_end.wday)
    created_ats = @all_typing_results
      .where(created_at: target_start.beginning_of_day..today.end_of_day)
      .pluck(:created_at)
    daily_counts = Hash.new(0)
    created_ats.each { |ts| daily_counts[ts.to_date] += 1 }
    @heatmap_days = (padded_start..padded_end).map do |date|
      in_year = date >= target_start && date <= target_end
      in_range = in_year && date <= today
      { date: date, count: in_range ? daily_counts[date] : 0, in_range: in_range, in_year: in_year }
    end

    # 実績: 未通知を取得してから既読マーク
    @new_achievements = current_user.user_achievements.where(notified_at: nil).to_a
    current_user.user_achievements.where(notified_at: nil).update_all(notified_at: Time.current) if @new_achievements.any?
    @granted_achievement_keys = current_user.user_achievements.pluck(:achievement_key).to_set
  end

  def show
    @typing_result = TypingResult.find(params[:id])
    authorize @typing_result
  end

  def update
    @typing_result = TypingResult.find(params[:id])
    authorize @typing_result

    article = @typing_result.article
    if article&.update(title: params.permit(:title)[:title])
      redirect_to typing_history_path(@typing_result), notice: "記事タイトルを更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :show, status: :unprocessable_entity
    end
  end

  def chart_data
    authorize TypingResult, :index?
    results = policy_scope(TypingResult).order(created_at: :desc).limit(30).to_a.reverse

    render json: [
      { name: "CPM", data: results.map { |r| [ r.created_at.strftime("%m月%d日 %H:%M"), r.cpm ] } }
    ]
  end
end
