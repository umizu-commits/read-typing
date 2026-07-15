require 'rails_helper'

RSpec.describe "ログイン・ログアウト", type: :request do
  let(:user) { create(:user) }

  describe "POST /users/sign_in" do
    context "有効な情報の場合" do
      it "ログインに成功しトップページにリダイレクトされる" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: "password123"
          }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "無効な情報の場合" do
      it "パスワードが誤っていればログインに失敗する" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: "wrongpassword"
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "未ログイン時のタイピング結果がある場合" do
      let(:pending_result_params) do
        {
          wpm: 60.0,
          cpm: 300.0,
          accuracy: 95.0,
          miss_count: 3,
          elapsed_time: 120,
          article_text: "ログイン後に保存するテスト用テキストです。"
        }
      end

      it "ログイン後に結果を保存してセッションから削除する" do
        post typing_results_path, params: pending_result_params

        expect {
          post user_session_path, params: {
            user: { email: user.email, password: "password123" }
          }
        }.to change(user.typing_results, :count).by(1)

        expect(user.typing_results.last.article_text).to eq pending_result_params[:article_text]
        expect(session[:pending_typing_result]).to be_nil
      end
    end
  end

  describe "DELETE /users/sign_out" do
    it "ログアウトに成功しトップページにリダイレクトされる" do
      sign_in user
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
