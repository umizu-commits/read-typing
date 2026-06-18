require "rails_helper"

RSpec.describe ArticleBodyExtractor do
  def build_html(title: nil, og_title: nil, body: "")
    og_tag = og_title ? %(<meta property="og:title" content="#{og_title}">) : ""
    title_tag = title ? "<title>#{title}</title>" : ""
    <<~HTML
      <html><head>#{og_tag}#{title_tag}</head>
      <body><article><p>#{body}</p></article></body></html>
    HTML
  end

  describe "#call" do
    context "タイトル抽出" do
      let(:body_text) { "a" * 50 }

      it "og:titleが存在する場合はog:titleを返す" do
        html = build_html(og_title: "OGタイトル", title: "titleタグ", body: body_text)
        result = described_class.new(html).call
        expect(result.title).to eq "OGタイトル"
      end

      it "og:titleがない場合はtitleタグを返す" do
        html = build_html(title: "titleタグ", body: body_text)
        result = described_class.new(html).call
        expect(result.title).to eq "titleタグ"
      end

      it "どちらもない場合はnilを返す" do
        html = build_html(body: body_text)
        result = described_class.new(html).call
        expect(result.title).to be_nil
      end

      it "255文字を超える場合は255文字に切り詰める" do
        long_title = "a" * 300
        html = build_html(og_title: long_title, body: body_text)
        result = described_class.new(html).call
        expect(result.title.length).to eq 255
      end
    end
  end
end
