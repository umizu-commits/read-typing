class TypingHistoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize TypingResult, :index?
    @all_typing_results = policy_scope(TypingResult)
    @typing_results = @all_typing_results.recent.page(params[:page]).per(10)
    @active_tab = params[:tab] == "list" ? "list" : "summary"

    @typing_history_summary = TypingHistorySummary.new(
      typing_results: @all_typing_results,
      period: params[:period]
    )

    @new_achievements = current_user.user_achievements.where(notified_at: nil).to_a
    mark_achievements_as_notified(@new_achievements)
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
    authorize article, :update? if article
    if article&.update(title: params.permit(:title)[:title])
      redirect_to typing_history_path(@typing_result), notice: "記事タイトルを更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def mark_achievements_as_notified(achievements)
    achievement_ids = achievements.map(&:id)
    return if achievement_ids.empty?

    current_user.user_achievements
      .where(id: achievement_ids, notified_at: nil)
      .update_all(notified_at: Time.current)
  end
end
