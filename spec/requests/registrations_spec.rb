require 'rails_helper'

RSpec.describe "ユーザー登録", type: :request do
  describe "POST /users" do
    context "有効な情報の場合" do
      it "登録に成功しトップページにリダイレクトされる" do
        post user_registration_path, params: {
          user: {
            email: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "無効な情報の場合" do
      it "パスワードが一致しなければ登録に失敗する" do
        post user_registration_path, params: {
          user: {
            email: "newuser@example.com",
            password: "password123",
            password_confirmation: "wrongpassword"
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
          article_text: "登録後に保存するテスト用テキストです。"
        }
      end

      it "登録後に結果を保存する" do
        post typing_results_path, params: pending_result_params

        expect {
          post user_registration_path, params: {
            user: {
              email: "pending-result-user@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        }.to change(TypingResult, :count).by(1)

        registered_user = User.find_by!(email: "pending-result-user@example.com")
        expect(registered_user.typing_results.last.article_text).to eq pending_result_params[:article_text]
      end
    end
  end
end
