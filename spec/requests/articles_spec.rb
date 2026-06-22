require 'rails_helper'

RSpec.describe "保存記事", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /articles" do
    context "未ログインの場合" do
      it "ログインページにリダイレクトされること" do
        get articles_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常にアクセスできること" do
        get articles_path
        expect(response).to have_http_status(:success)
      end

      it "自分の記事が表示されること" do
        create(:article, user: user, title: "自分の記事")
        get articles_path
        expect(response.body).to include("自分の記事")
      end

      it "他ユーザーの記事は表示されないこと" do
        create(:article, user: other_user, title: "他人の記事")
        get articles_path
        expect(response.body).not_to include("他人の記事")
      end

      it "記事が0件のとき「保存された記事がありません」と表示されること" do
        get articles_path
        expect(response.body).to include("保存された記事がありません")
      end

      context "検索機能" do
        let!(:rails_article) { create(:article, user: user, title: "Rails入門") }
        let!(:python_article) { create(:article, user: user, title: "Python入門") }

        it "キーワードに一致する記事のみ表示されること" do
          get articles_path, params: { q: "Rails" }
          expect(response.body).to include("Rails入門")
          expect(response.body).not_to include("Python入門")
        end

        it "前後の空白を除去して検索されること" do
          get articles_path, params: { q: "  Rails  " }
          expect(response.body).to include("Rails入門")
        end

        it "キーワードが一致しない場合「一致する記事が見つかりませんでした」と表示されること" do
          get articles_path, params: { q: "Java" }
          expect(response.body).to include("一致する記事が見つかりませんでした")
        end

        it "キーワードが空の場合は全件表示されること" do
          get articles_path, params: { q: "" }
          expect(response.body).to include("Rails入門")
          expect(response.body).to include("Python入門")
        end
      end

      context "並び替え機能" do
        let!(:old_article) { travel_to(2.days.ago) { create(:article, user: user, title: "古い記事") } }
        let!(:new_article) { travel_to(1.day.ago)  { create(:article, user: user, title: "新しい記事") } }

        it "sort=newestで新しい順に表示されること" do
          get articles_path, params: { sort: "newest" }
          expect(response.body.index("新しい記事")).to be < response.body.index("古い記事")
        end

        it "sort=oldestで古い順に表示されること" do
          get articles_path, params: { sort: "oldest" }
          expect(response.body.index("古い記事")).to be < response.body.index("新しい記事")
        end

        it "不正なsortキーはデフォルト（新しい順）で表示されること" do
          get articles_path, params: { sort: "invalid" }
          expect(response.body.index("新しい記事")).to be < response.body.index("古い記事")
        end
      end
    end
  end

  describe "DELETE /articles/:id" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "自分の記事を削除できること" do
        article = create(:article, user: user)
        expect {
          delete article_path(article)
        }.to change(Article, :count).by(-1)
      end

      it "他ユーザーの記事は削除できないこと" do
        article = create(:article, user: other_user)
        expect {
          delete article_path(article)
        }.not_to change(Article, :count)
      end
    end
  end
end
