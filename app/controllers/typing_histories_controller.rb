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

    # グラフ用データをインラインで生成（別途AJAXリクエスト不要）
    chart_results = @all_typing_results.order(created_at: :desc).limit(30).includes(:article).to_a.reverse
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
