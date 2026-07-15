require 'rails_helper'
require 'nokogiri'

RSpec.describe "タイピング履歴", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  def chart_titles
    chart = Nokogiri::HTML(response.body).at_css("canvas[data-chart-data-value]")
    JSON.parse(chart["data-chart-data-value"]).map { |point| point.fetch("title") }
  end

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
        create(:typing_result, user: other_user, wpm: 99.9)
        get typing_histories_path
        expect(response.body).not_to include("99.9")
      end

      it "履歴が0件のとき「まだ履歴がありません」と表示される" do
        get typing_histories_path
        expect(response.body).to include("まだ履歴がありません")
      end

      context "ページネーション" do
        before do
          11.times do |index|
            create(
              :typing_result,
              user: user,
              article_title: "ページネーション対象#{index}",
              created_at: (11 - index).minutes.ago
            )
          end
        end

        it "2ページ目には11件目の結果だけが表示される" do
          get typing_histories_path, params: { tab: "list", page: 2 }

          expect(response.body).to include("ページネーション対象0")
          expect(response.body).not_to include("ページネーション対象10")
          expect(response.body).to include("全 11 セッション中 11-11 を表示中")
        end
      end

      context "期間フィルタ" do
        before do
          create(:typing_result, user: user, article_title: "直近7日", created_at: 6.days.ago)
          create(:typing_result, user: user, article_title: "直近30日", created_at: 29.days.ago)
          create(:typing_result, user: user, article_title: "31日より前", created_at: 31.days.ago)
        end

        it "デフォルトでは直近30日間の結果だけをグラフに表示する" do
          get typing_histories_path

          expect(chart_titles).to contain_exactly("直近7日", "直近30日")
        end

        it "period=7dでは直近7日間の結果だけをグラフに表示する" do
          get typing_histories_path, params: { period: "7d" }

          expect(chart_titles).to contain_exactly("直近7日")
        end

        it "period=allでは期間外の結果もグラフに表示する" do
          get typing_histories_path, params: { period: "all" }

          expect(chart_titles).to contain_exactly("直近7日", "直近30日", "31日より前")
        end
      end

      context "実績通知" do
        let!(:unread_achievement) do
          user.user_achievements.create!(achievement_key: "first_typing", achieved_at: Time.current)
        end
        let!(:already_notified_achievement) do
          user.user_achievements.create!(
            achievement_key: "first_article",
            achieved_at: 1.day.ago,
            notified_at: 1.hour.ago
          )
        end
        let!(:other_users_unread_achievement) do
          other_user.user_achievements.create!(achievement_key: "first_typing", achieved_at: Time.current)
        end

        before { create(:typing_result, user: user) }

        it "自分の未読実績だけを表示して既読にする" do
          expect {
            get typing_histories_path
          }.to change { unread_achievement.reload.notified_at }.from(nil)

          expect(response.body).to include("新しい実績を獲得しました！")
          expect(response.body).to include("はじめの一歩")
          expect(already_notified_achievement.reload.notified_at).to be_present
          expect(other_users_unread_achievement.reload.notified_at).to be_nil
        end
      end
    end
  end

  describe "GET /typing/histories/:id" do
    let(:typing_result) { create(:typing_result, user: user, cpm: 420.0) }

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get typing_history_path(typing_result)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "自分のタイピング結果を表示できる" do
        get typing_history_path(typing_result)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("420.0")
      end

      it "他ユーザーのタイピング結果は表示できない" do
        other_result = create(:typing_result, user: other_user)

        get typing_history_path(other_result)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /typing/histories/:id" do
    context "未ログインの場合" do
      it "記事タイトルを更新できない" do
        article = create(:article, user: user, title: "更新前のタイトル")
        typing_result = create(:typing_result, user: user, article: article)

        expect {
          patch typing_history_path(typing_result), params: { title: "不正な更新" }
        }.not_to change { article.reload.title }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "自分の記事に紐づくタイピング結果から記事タイトルを更新できる" do
        article = create(:article, user: user, title: "更新前のタイトル")
        typing_result = create(:typing_result, user: user, article: article)

        patch typing_history_path(typing_result), params: { title: "更新後のタイトル" }

        expect(response).to redirect_to(typing_history_path(typing_result))
        expect(article.reload.title).to eq("更新後のタイトル")
      end

      it "他ユーザーのタイピング結果から記事タイトルを更新できない" do
        article = create(:article, user: other_user, title: "他ユーザーの記事")
        typing_result = create(:typing_result, user: other_user, article: article)

        expect {
          patch typing_history_path(typing_result), params: { title: "不正な更新" }
        }.not_to change { article.reload.title }

        expect(response).to redirect_to(root_path)
      end

      it "自分の結果に紐づく他ユーザーの記事タイトルは更新できない" do
        article = create(:article, user: other_user, title: "他ユーザーの記事")
        # 所有者整合性バリデーション導入前に保存された不整合データを再現する。
        typing_result = create(:typing_result, user: user)
        typing_result.update_column(:article_id, article.id)

        expect {
          patch typing_history_path(typing_result), params: { title: "不正な更新" }
        }.not_to change { article.reload.title }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /typing/histories/chart_data" do
    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get chart_data_typing_histories_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "自分の結果だけを古い順にJSONで返す" do
        create(:typing_result, user: user, cpm: 120.0, created_at: 2.hours.ago)
        create(:typing_result, user: other_user, cpm: 999.0, created_at: 1.hour.ago)
        create(:typing_result, user: user, cpm: 240.0, created_at: Time.current)

        get chart_data_typing_histories_path

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.size).to eq(1)
        expect(response.parsed_body.first.fetch("name")).to eq("CPM")
        expect(response.parsed_body.first.fetch("data").map(&:last)).to eq([ 120.0, 240.0 ])
      end
    end
  end
end
