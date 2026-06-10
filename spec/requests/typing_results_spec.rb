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
    end
  end
end
