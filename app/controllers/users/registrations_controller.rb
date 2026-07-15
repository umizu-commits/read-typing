class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :require_no_authentication, only: [ :cancel ]
  before_action :authenticate_user!, only: [ :cancel, :destroy ]

  # Confirmable 有効時は、確認メール送信後にこのコールバックが呼ばれる。
  # メール確認待ちでも、登録前に保存したタイピング結果を失わないようにする。
  def after_inactive_sign_up_path_for(resource)
    save_pending_typing_result(resource)
    root_path
  end

  def cancel
    # 退会確認画面
  end

  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    flash[:notice] = "退会が完了しました。ご利用ありがとうございました。"
    redirect_to root_path, status: :see_other
  end
end
