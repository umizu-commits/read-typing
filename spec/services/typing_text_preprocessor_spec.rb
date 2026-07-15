require "rails_helper"

RSpec.describe TypingTextPreprocessor do
  describe "#call" do
    context "テキストを正規化するとき" do
      it "改行・空白を正規化し、連続する空行を2行までにする" do
        suffix = "x" * 50
        input = "  alpha\u3000\t beta  \r\n \t gamma \n\n\n\n delta  " + suffix

        result = described_class.new(input).call

        expect(result.success?).to be(true)
        expect(result.body).to eq("alpha beta\ngamma\n\ndelta #{suffix}")
        expect(result.error_message).to be_nil
      end

      it "制御文字、ゼロ幅・方向制御文字、絵文字を除去する" do
        suffix = "a" * 50
        input = "前\u0000\u0007\u200B\u200F\u202E\uFEFF😀後" + suffix

        result = described_class.new(input).call

        expect(result.success?).to be(true)
        expect(result.body).to eq("前後#{suffix}")
      end

      it "不正なUTF-8バイト列を除去して処理を続行する" do
        input = (("a" * 25).b + "\xFF".b + ("b" * 25).b).force_encoding(Encoding::UTF_8)

        result = described_class.new(input).call

        expect(result.success?).to be(true)
        expect(result.body).to eq(("a" * 25) + ("b" * 25))
      end
    end

    context "本文の長さを検証するとき" do
      it "50文字ちょうどの本文は成功する" do
        input = "a" * described_class::MIN_BODY_LENGTH

        result = described_class.new(input).call

        expect(result.success?).to be(true)
        expect(result.body).to eq(input)
      end

      it "50文字未満の本文はエラーにする" do
        input = "a" * (described_class::MIN_BODY_LENGTH - 1)

        result = described_class.new(input).call

        expect(result.success?).to be(false)
        expect(result.body).to be_nil
        expect(result.error_message).to eq("テキストが短すぎます")
      end
    end

    context "本文が最大長を超えるとき" do
      it "句点がなければ最大長で切り詰める" do
        input = "a" * (described_class::MAX_BODY_LENGTH + 1)

        result = described_class.new(input).call

        expect(result.success?).to be(true)
        expect(result.body).to eq("a" * described_class::MAX_BODY_LENGTH)
      end

      it "最大長内にある最後の句点で丸める" do
        first_sentence = ("a" * (described_class::MAX_BODY_LENGTH - 100)) + "。"
        last_sentence = ("b" * 50) + "。"
        input = "#{first_sentence}#{last_sentence}#{"c" * 100}"

        result = described_class.new(input).call

        expect(result.success?).to be(true)
        expect(result.body).to eq("#{first_sentence}#{last_sentence}")
      end
    end
  end
end
