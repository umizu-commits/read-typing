require 'rails_helper'

RSpec.describe "タイピング", type: :request do
  describe "GET /typing" do
    context "article_id が指定されていない場合" do
      it "タイピング画面が表示される" do
        get typing_path
        expect(response).to have_http_status(:success)
      end
    end

    context "存在しない article_id の場合" do
      it "ルートにリダイレクトされる" do
        get typing_path(article_id: 0)
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログインの場合" do
      it "user_id が nil の Article ならアクセスできる" do
        article = create(:article, user: nil)
        get typing_path(article_id: article.id)
        expect(response).to have_http_status(:success)
      end

      it "他人（user_id 有り）の Article はアクセスできない" do
        article = create(:article, user: create(:user))
        get typing_path(article_id: article.id)
        expect(response).to redirect_to(root_path)
      end
    end

    context "ログイン中の場合" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "自分の Article にアクセスできる" do
        article = create(:article, user: user)
        get typing_path(article_id: article.id)
        expect(response).to have_http_status(:success)
      end

      it "他人の Article にアクセスできない" do
        article = create(:article, user: create(:user))
        get typing_path(article_id: article.id)
        expect(response).to redirect_to(root_path)
      end

      it "user_id が nil の Article にもアクセスできない" do
        article = create(:article, user: nil)
        get typing_path(article_id: article.id)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /typing/result" do
    it "未ログインでも結果画面にアクセスできる" do
      get typing_result_path
      expect(response).to have_http_status(:success)
    end
  end
end
