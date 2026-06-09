class TypingHistoriesController < ApplicationController
  before_action :authenticate_user!
  def index
    authorize TypingResult, :index?
    # 現在のユーザーの結果だけを返す
    @all_typing_results = policy_scope(TypingResult)
    # ページネーション適用（テーブル表示用）
    @typing_results = @all_typing_results.recent.page(params[:page]).per(10)
  end
end
