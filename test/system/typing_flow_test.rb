require "application_system_test_case"

class TypingFlowTest < ApplicationSystemTestCase
  test "保存せずにテキストからタイピングを開始できる" do
    visit root_path

    click_button "テキストを貼り付け"
    find("textarea[data-typing-form-target='text']").set("あ" * 50)
    click_button "保存せずに練習を開始する"

    assert_current_path typing_path
    assert_text "50文字"
    assert_text "最初の文字を入力するとタイマーが開始されます"
  end

  test "結果画面へ直接アクセスするとトップへ戻る" do
    visit typing_result_path

    assert_current_path root_path
  end

  test "英字を最後まで入力すると結果画面へ遷移する" do
    visit root_path
    page.execute_script("sessionStorage.setItem('typing_text', 'ab')")
    visit typing_path

    type_text("a", "b", total: 2)

    assert_current_path typing_result_path
    assert_text "練習完了！お疲れ様でした。"
  end

  test "空白は入力せずに次の文字へ進める" do
    visit root_path
    page.execute_script("sessionStorage.setItem('typing_text', 'a b')")
    visit typing_path

    type_text("a", "b", total: 3)

    assert_current_path typing_result_path
    assert_text "練習完了！お疲れ様でした。"
  end

  test "再挑戦すると入力中の文字を初期化できる" do
    visit root_path
    page.execute_script("sessionStorage.setItem('typing_text', 'ab')")
    visit typing_path

    type_text("a", total: 2)
    assert_equal "a", find("[data-typing-target='typedWindow']").text

    click_button "再挑戦する"

    assert_equal "", find("[data-typing-target='typedWindow']").text
    assert_text "0/2文字"

    type_text("a", "b", total: 2)
    assert_current_path typing_result_path
  end

  private

  def type_text(*keys, total:)
    assert_selector("[data-typing-target='text'] .typing-char", count: total)

    input = find("textarea[data-typing-target='input']", visible: :all)
    page.execute_script("arguments[0].classList.remove('opacity-0')", input)
    input.send_keys(*keys)
  end
end
