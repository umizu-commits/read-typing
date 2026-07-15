require "rails_helper"

RSpec.describe ArticleTextForm do
  let(:valid_body) { "あ" * 50 }

  describe "バリデーション" do
    subject(:form) { described_class.new(body: body, title: title, user: nil) }
    let(:title) { "テスト" }

    context "bodyが50文字以上の場合" do
      let(:body) { valid_body }

      it "バリデーションが通る" do
        expect(form).to be_valid
      end
    end

    context "bodyが空の場合" do
      let(:body) { "" }

      it "バリデーションエラーになる" do
        expect(form).not_to be_valid
        expect(form.errors[:body]).to be_present
      end
    end

    context "bodyが50文字未満の場合" do
      let(:body) { "あ" * 49 }

      it "バリデーションエラーになる" do
        expect(form).not_to be_valid
        expect(form.errors[:body]).to be_present
      end
    end

    context "bodyが10,000文字を超える場合" do
      let(:body) { "あ" * 10_001 }

      it "バリデーションエラーになる" do
        expect(form).not_to be_valid
        expect(form.errors[:body]).to be_present
      end
    end

    context "titleが255文字を超える場合" do
      let(:body) { valid_body }
      let(:title) { "あ" * 256 }

      it "バリデーションエラーになる" do
        expect(form).not_to be_valid
        expect(form.errors[:title]).to be_present
      end
    end
  end

  describe "#save" do
    subject(:form) { described_class.new(body: valid_body, title: title, user: user_arg) }
    let(:title) { "テストタイトル" }
    let(:user_arg) { nil }

    context "有効なデータの場合" do
      it "trueを返す" do
        expect(form.save).to be true
      end

      it "Articleが1件作成される" do
        expect { form.save }.to change(Article, :count).by(1)
      end

      it "source_typeが'text'で保存される" do
        form.save
        expect(form.article.source_type).to eq("text")
      end

      it "urlがnilで保存される" do
        form.save
        expect(form.article.url).to be_nil
      end
    end

    context "titleが空文字の場合" do
      let(:title) { "" }

      it "titleがnilで保存される" do
        form.save
        expect(form.article.title).to be_nil
      end
    end

    context "userを渡した場合" do
      let(:user_arg) { create(:user) }

      it "そのuserに紐づいて保存される" do
        form.save
        expect(form.article.user).to eq(user_arg)
      end

      it "expires_atがnilになる" do
        form.save
        expect(form.article.expires_at).to be_nil
      end
    end

    context "userがnil（未ログイン）の場合" do
      let(:user_arg) { nil }

      it "user_idがnilで保存される" do
        form.save
        expect(form.article.user_id).to be_nil
      end

      it "expires_atが7日後としてセットされる" do
        form.save
        expect(form.article.expires_at).to be_within(1.minute).of(7.days.from_now)
      end
    end

    context "tag_namesを渡した場合" do
      subject(:form) { described_class.new(body: valid_body, title: title, user: nil, tag_names: "Rails, Ruby") }

      it "タグが記事に紐づく" do
        form.save
        expect(form.article.tags.map(&:name)).to match_array([ "Rails", "Ruby" ])
      end
    end

    context "tag_namesが空文字の場合" do
      subject(:form) { described_class.new(body: valid_body, title: title, user: nil, tag_names: "") }

      it "タグなしで保存される" do
        form.save
        expect(form.article.tags).to be_empty
      end
    end

    context "20文字を超えるタグ名を渡した場合" do
      subject(:form) { described_class.new(body: valid_body, title: title, user: nil, tag_names: "a" * 21) }

      it "保存せずにタグ名のエラーを返す" do
        expect(form.save).to be false
        expect(form.errors[:tag_names]).to be_present
      end
    end
  end
end
