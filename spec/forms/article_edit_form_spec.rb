require "rails_helper"

RSpec.describe ArticleEditForm do
  let(:article) { create(:article) }
  let(:preprocessor) { instance_double(TypingTextPreprocessor) }
  let(:preprocess_result) do
    TypingTextPreprocessor::Result.new(success?: true, body: "a" * 50, error_message: nil)
  end

  before do
    allow(TypingTextPreprocessor).to receive(:new).and_return(preprocessor)
    allow(preprocessor).to receive(:call).and_return(preprocess_result)
  end

  describe "#update" do
    subject(:form) { described_class.new(article: article, params: params) }

    context "有効なデータの場合" do
      let(:params) { { title: "新タイトル", body: "a" * 50, category: nil } }

      it "trueを返す" do
        expect(form.update).to be true
      end

      it "titleが更新される" do
        form.update
        expect(article.reload.title).to eq("新タイトル")
      end

      it "bodyが前処理後の値で更新される" do
        form.update
        expect(article.reload.body).to eq("a" * 50)
      end
    end

    context "bodyが50文字未満の場合" do
      let(:params) { { body: "a" * 49 } }

      it "falseを返す" do
        expect(form.update).to be false
      end

      it "bodyのエラーがセットされる" do
        form.update
        expect(form.errors[:body]).to be_present
      end
    end

    context "titleが255文字を超える場合" do
      let(:params) { { title: "a" * 256 } }

      it "falseを返す" do
        expect(form.update).to be false
      end
    end

    context "bodyが空文字の場合" do
      let(:params) { { title: "新タイトル", body: "" } }

      it "bodyを前処理せずtrueを返す" do
        expect(TypingTextPreprocessor).not_to receive(:new)
        expect(form.update).to be true
      end

      it "bodyが変更されない" do
        original_body = article.body
        form.update
        expect(article.reload.body).to eq(original_body)
      end
    end

    context "titleが空文字の場合" do
      let(:params) { { title: "", body: "" } }

      it "titleがnilで保存される" do
        form.update
        expect(article.reload.title).to be_nil
      end
    end

    context "tag_namesを渡した場合" do
      let(:params) { { body: "", tag_names: "Rails, Ruby" } }

      it "タグが記事に紐づく" do
        form.update
        expect(article.tags.map(&:name)).to match_array([ "Rails", "Ruby" ])
      end
    end

    context "tag_namesが空文字の場合" do
      let!(:tag) { Tag.find_or_create_by!(name: "既存タグ") }

      before { article.tags = [ tag ] }

      let(:params) { { body: "", tag_names: "" } }

      it "タグが全削除される" do
        form.update
        expect(article.tags).to be_empty
      end
    end

    context "tag_namesがnilの場合" do
      let!(:tag) { Tag.find_or_create_by!(name: "既存タグ") }

      before { article.tags = [ tag ] }

      let(:params) { { body: "", tag_names: nil } }

      it "タグが変更されない" do
        form.update
        expect(article.tags.map(&:name)).to eq([ "既存タグ" ])
      end
    end
  end
end
