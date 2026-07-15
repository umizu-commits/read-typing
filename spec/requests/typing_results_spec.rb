require 'rails_helper'

RSpec.describe "タイピング結果保存", type: :request do
  let(:user) { create(:user) }
  let(:valid_params) do
    {
      wpm: 60.0,
      cpm: 300.0,
      accuracy: 95.0,
      miss_count: 3,
      elapsed_time: 120,
      article_text: "テスト用の記事テキストです。"
    }
  end

  describe "POST /typing/results" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "タイピング結果が1件保存される" do
        expect {
          post typing_results_path, params: valid_params
        }.to change(TypingResult, :count).by(1)
      end

      it "各値が正しく保存される" do
        post typing_results_path, params: valid_params
        result = TypingResult.last
        expect(result.wpm).to eq 60.0
        expect(result.accuracy).to eq 95.0
        expect(result.miss_count).to eq 3
        expect(result.elapsed_time).to eq 120
        expect(result.article_text).to eq "テスト用の記事テキストです。"
      end

      it "自分の記事と正解文字数を紐づけて保存できる" do
        article = create(:article, user: user)

        post typing_results_path, params: valid_params.merge(
          article_id: article.id,
          article_title: "保存時タイトル",
          article_text: "a" * 50,
          correct_count: 42
        )

        result = TypingResult.last
        expect(result.article).to eq article
        expect(result.article_title).to eq "保存時タイトル"
        expect(result.correct_count).to eq 42
        expect(result.cpm).to eq 300.0
      end

      it "ログインユーザーに紐づいて保存される" do
        post typing_results_path, params: valid_params
        expect(TypingResult.last.user).to eq user
      end

      it "レスポンスのstatusがsavedである" do
        post typing_results_path, params: valid_params
        expect(response.parsed_body["status"]).to eq "saved"
      end
    end

    context "ログイン済みかつ無効な値の場合" do
      before { sign_in user }

      it "タイピング結果が保存されない" do
        expect {
          post typing_results_path, params: valid_params.merge(wpm: nil)
        }.not_to change(TypingResult, :count)
      end

      it "他ユーザーの記事を紐づけた結果は保存されない" do
        other_article = create(:article, user: create(:user))

        expect {
          post typing_results_path, params: valid_params.merge(article_id: other_article.id)
        }.not_to change(TypingResult, :count)

        expect(response.parsed_body["status"]).to eq "failed"
      end

      it "存在しない記事を紐づけた結果は保存されない" do
        expect {
          post typing_results_path, params: valid_params.merge(article_id: 0)
        }.not_to change(TypingResult, :count)

        expect(response.parsed_body["status"]).to eq "failed"
      end

      it "本文より大きい正解文字数の結果は保存されない" do
        expect {
          post typing_results_path, params: valid_params.merge(correct_count: valid_params[:article_text].length + 1)
        }.not_to change(TypingResult, :count)

        expect(response.parsed_body["status"]).to eq "failed"
      end

      it "レスポンスのstatusがfailedである" do
        post typing_results_path, params: valid_params.merge(wpm: nil)
        expect(response.parsed_body["status"]).to eq "failed"
      end
    end

    context "未ログインの場合" do
      it "タイピング結果が保存されない" do
        expect {
          post typing_results_path, params: valid_params
        }.not_to change(TypingResult, :count)
      end

      it "レスポンスのstatusがskippedである" do
        post typing_results_path, params: valid_params
        expect(response.parsed_body["status"]).to eq "skipped"
      end

      it "ログイン後に保存するため結果をセッションへ保持する" do
        post typing_results_path, params: valid_params

        expect(session[:pending_typing_result]).to include(
          "wpm" => "60.0",
          "cpm" => "300.0",
          "article_text" => "テスト用の記事テキストです。"
        )
      end
    end
  end

  describe "POST /typing/results/share_achievement" do
    it "未ログインでは実績を付与しない" do
      post "/typing/results/share_achievement"

      expect(response.parsed_body["status"]).to eq "skipped"
    end

    it "ログイン中はSNS共有実績を一度だけ付与する" do
      sign_in user

      expect {
        post "/typing/results/share_achievement"
      }.to change(user.user_achievements, :count).by(1)
      expect(response.parsed_body["status"]).to eq "ok"
      expect(user.user_achievements.last.achievement_key).to eq "sns_share"

      expect {
        post "/typing/results/share_achievement"
      }.not_to change(user.user_achievements, :count)
    end
  end
end
