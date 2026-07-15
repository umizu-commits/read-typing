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

    context "サイト名サフィックス除去" do
      let(:body_text) { "a" * 50 }

      {
        "qiita.com"       => [ "記事タイトル - Qiita",        "記事タイトル" ],
        "zenn.dev"        => [ "記事タイトル | Zenn",         "記事タイトル" ],
        "note.com"        => [ "記事タイトル | note",         "記事タイトル" ],
        "medium.com"      => [ "記事タイトル - Medium",       "記事タイトル" ],
        "dev.to"          => [ "記事タイトル | DEV Community", "記事タイトル" ],
        "speakerdeck.com" => [ "スライドタイトル | Speaker Deck", "スライドタイトル" ]
      }.each do |domain, (raw_title, expected)|
        it "#{domain} のサフィックスを除去する" do
          html = build_html(og_title: raw_title, body: body_text)
          result = described_class.new(html, url: "https://#{domain}/article/123").call
          expect(result.title).to eq expected
        end
      end

      it "URLが指定されていない場合はサフィックスを除去しない" do
        html = build_html(og_title: "記事タイトル - Qiita", body: body_text)
        result = described_class.new(html).call
        expect(result.title).to eq "記事タイトル - Qiita"
      end

      it "未登録ドメインのサフィックスは除去しない" do
        html = build_html(og_title: "記事タイトル | Example", body: body_text)
        result = described_class.new(html, url: "https://example.com/article").call
        expect(result.title).to eq "記事タイトル | Example"
      end

      it "タイトル中の区切り文字はサフィックス以外除去しない" do
        html = build_html(og_title: "React vs Vue - 比較まとめ - Qiita", body: body_text)
        result = described_class.new(html, url: "https://qiita.com/article").call
        expect(result.title).to eq "React vs Vue - 比較まとめ"
      end

      it "www. プレフィックス付きURLでもサフィックスを除去する" do
        html = build_html(og_title: "記事タイトル - Qiita", body: body_text)
        result = described_class.new(html, url: "https://www.qiita.com/article").call
        expect(result.title).to eq "記事タイトル"
      end
    end

    context "本文抽出" do
      it "本文要素だけを結合し不要な要素を除外する" do
        html = <<~HTML
          <html><body>
            <article>
              <header>ヘッダーは本文に含めない</header>
              <h1>見出し</h1>
              <p>これは十分な長さを持つ本文の一段落目です。テストのための文字列を追加します。</p>
              <pre>コードブロックは本文に含めない</pre>
              <ul><li>リスト項目</li></ul>
              <footer>フッターは本文に含めない</footer>
            </article>
          </body></html>
        HTML

        result = described_class.new(html).call

        expect(result).to be_success
        expect(result.body).to eq(
          "見出し\n\nこれは十分な長さを持つ本文の一段落目です。テストのための文字列を追加します。\n\nリスト項目"
        )
      end

      it "本文要素がない場合はエラーを返す" do
        html = "<html><body><article><div>本文ではない要素</div></article></body></html>"

        result = described_class.new(html).call

        expect(result).not_to be_success
        expect(result.error_message).to eq("本文が見つかりませんでした")
      end

      it "本文が50文字未満の場合はエラーを返す" do
        html = build_html(body: "a" * 49)

        result = described_class.new(html).call

        expect(result).not_to be_success
        expect(result.error_message).to eq("本文が短すぎます")
      end
    end
  end
end
