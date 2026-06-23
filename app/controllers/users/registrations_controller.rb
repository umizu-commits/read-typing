class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :require_no_authentication, only: [ :cancel ]
  before_action :authenticate_user!, only: [ :cancel, :destroy ]

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
