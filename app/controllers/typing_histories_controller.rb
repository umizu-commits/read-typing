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
