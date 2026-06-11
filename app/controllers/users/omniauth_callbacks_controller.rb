class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    handle_omniauth(kind: "GitHub")
  end

  def google_oauth2
    handle_omniauth(kind: "Google")
  end

  def failure
    redirect_to root_path, alert: "ログインに失敗しました。"
  end

  private

  def handle_omniauth(kind:)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      provider = request.env["omniauth.auth"].provider
      session["devise.#{provider}_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
