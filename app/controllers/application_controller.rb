class ApplicationController < ActionController::Base
  # PunditをApplicationControllerに組み込む
  include Pundit::Authorization

  # 認可エラー時に自動で呼ばれる処理を登録
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # 登録後のリダイレクトページを明示する
  def after_sign_up_path_for(resource)
    save_pending_typing_result(resource)
    root_path
  end

  # ログイン後のリダイレクトページを明示する
  def after_sign_in_path_for(resource)
    save_pending_typing_result(resource)
    root_path
  end

  # ログアウト後のリダイレクトページを明示する
  def after_sign_out_path_for(resource)
    root_path
  end

  private

  def user_not_authorized
    flash[:alert] = "このページへのアクセス権限がありません。"
    redirect_to root_path
  end

  def save_pending_typing_result(user)
    pending = session.delete(:pending_typing_result)
    return unless pending
    user.typing_results.create(pending)
  end
end
