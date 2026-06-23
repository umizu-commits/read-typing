require "rails_helper"

RSpec.describe AchievementGrantService do
  let(:user) { create(:user) }

  subject(:service) { described_class.new(user) }

  def grant_keys(context:, typing_result: nil)
    service.call(context: context, typing_result: typing_result)
  end

  describe "#call" do
    context "context: :typing_saved を渡した場合" do
      context "初回タイピングの場合" do
        before { create(:typing_result, user: user) }

        it "first_typingが付与される" do
          expect(grant_keys(context: :typing_saved)).to include("first_typing")
        end

        it "2回目の呼び出しではfirst_typingが重複付与されない" do
          grant_keys(context: :typing_saved)
          expect(grant_keys(context: :typing_saved)).not_to include("first_typing")
        end
      end

      context "タイピング回数が10回以上の場合" do
        before { create_list(:typing_result, 10, user: user) }

        it "typing_10が付与される" do
          expect(grant_keys(context: :typing_saved)).to include("typing_10")
        end
      end

      context "タイピング回数が9回の場合" do
        before { create_list(:typing_result, 9, user: user) }

        it "typing_10が付与されない" do
          expect(grant_keys(context: :typing_saved)).not_to include("typing_10")
        end
      end

      context "CPMが100以上の場合" do
        let(:result) { build(:typing_result, cpm: 100.0) }

        before { create(:typing_result, user: user) }

        it "cpm_100が付与される" do
          expect(grant_keys(context: :typing_saved, typing_result: result)).to include("cpm_100")
        end
      end

      context "CPMが200以上の場合" do
        let(:result) { build(:typing_result, cpm: 200.0) }

        before { create(:typing_result, user: user) }

        it "cpm_200が付与される" do
          expect(grant_keys(context: :typing_saved, typing_result: result)).to include("cpm_200")
        end
      end

      context "CPMが300以上の場合" do
        let(:result) { build(:typing_result, cpm: 300.0) }

        before { create(:typing_result, user: user) }

        it "cpm_300が付与される" do
          expect(grant_keys(context: :typing_saved, typing_result: result)).to include("cpm_300")
        end
      end

      context "CPMが99の場合" do
        let(:result) { build(:typing_result, cpm: 99.0) }

        before { create(:typing_result, user: user) }

        it "cpm_100が付与されない" do
          expect(grant_keys(context: :typing_saved, typing_result: result)).not_to include("cpm_100")
        end
      end

      context "正答率が100%の場合" do
        let(:result) { build(:typing_result, accuracy: 100.0) }

        before { create(:typing_result, user: user) }

        it "accuracy_100が付与される" do
          expect(grant_keys(context: :typing_saved, typing_result: result)).to include("accuracy_100")
        end
      end

      context "正答率が99.9%の場合" do
        let(:result) { build(:typing_result, accuracy: 99.9) }

        before { create(:typing_result, user: user) }

        it "accuracy_100が付与されない" do
          expect(grant_keys(context: :typing_saved, typing_result: result)).not_to include("accuracy_100")
        end
      end

      context "3日連続タイピングの場合" do
        before do
          travel_to(3.days.ago) { create(:typing_result, user: user) }
          travel_to(2.days.ago) { create(:typing_result, user: user) }
          travel_to(1.day.ago)  { create(:typing_result, user: user) }
        end

        it "streak_3が付与される" do
          expect(grant_keys(context: :typing_saved)).to include("streak_3")
        end
      end

      context "最終練習日が2日以上前の場合" do
        before do
          travel_to(3.days.ago) { create(:typing_result, user: user) }
          travel_to(2.days.ago) { create(:typing_result, user: user) }
          # 1日前が空白 → 最終練習日が2日前なのでストリーク途切れ
        end

        it "streak_3が付与されない" do
          expect(grant_keys(context: :typing_saved)).not_to include("streak_3")
        end
      end

      context "今日・昨日の2日連続の場合（1日猶予ルール）" do
        before do
          travel_to(1.day.ago) { create(:typing_result, user: user) }
          travel_to(Time.current) { create(:typing_result, user: user) }
        end

        it "streak_3はまだ付与されない" do
          expect(grant_keys(context: :typing_saved)).not_to include("streak_3")
        end

        it "first_typingは付与される" do
          expect(grant_keys(context: :typing_saved)).to include("first_typing")
        end
      end
    end

    context "context: :article_saved を渡した場合" do
      context "記事が1件ある場合" do
        before { create(:article, user: user) }

        it "first_articleが付与される" do
          expect(grant_keys(context: :article_saved)).to include("first_article")
        end
      end

      context "記事が2件以上ある場合（>= 1 の修正確認）" do
        before { create_list(:article, 2, user: user) }

        it "first_articleが付与される" do
          expect(grant_keys(context: :article_saved)).to include("first_article")
        end
      end

      context "記事が0件の場合" do
        it "first_articleが付与されない" do
          expect(grant_keys(context: :article_saved)).not_to include("first_article")
        end
      end
    end

    context "context: :sns_shared を渡した場合" do
      it "sns_shareが付与される" do
        expect(grant_keys(context: :sns_shared)).to include("sns_share")
      end

      it "2回目の呼び出しでは付与されない" do
        grant_keys(context: :sns_shared)
        expect(grant_keys(context: :sns_shared)).not_to include("sns_share")
      end
    end

    context "未知の context を渡した場合" do
      it "何も付与しない" do
        expect(grant_keys(context: :unknown)).to be_empty
      end
    end
  end
end
