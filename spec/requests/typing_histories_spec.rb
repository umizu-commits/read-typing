require 'rails_helper'

RSpec.describe "タイピング履歴", type: :request do
  let(:user) { create(:user) }

  describe "GET /typing/histories" do
    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get typing_histories_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常にアクセスできる" do
        get typing_histories_path
        expect(response).to have_http_status(:success)
      end

      it "自分のタイピング結果が表示される" do
        create(:typing_result, user: user, wpm: 55.5)
        get typing_histories_path
        expect(response.body).to include("55.5")
      end

      it "他ユーザーのタイピング結果は表示されない" do
        other_user = create(:user)
        create(:typing_result, user: other_user, wpm: 99.9)
        get typing_histories_path
        expect(response.body).not_to include("99.9")
      end

      it "履歴が0件のとき「まだ履歴がありません」と表示される" do
        get typing_histories_path
        expect(response.body).to include("まだ履歴がありません")
      end
    end
  end
end
