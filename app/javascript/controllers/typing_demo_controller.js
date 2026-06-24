import { Controller } from "@hotwired/stimulus"

// トップページのヒーロー直下に置くタイピングデモ
// 実際の typing 画面と同じ見た目で、文字を1つずつ自動入力するアニメーションをループ再生する
export default class extends Controller {
  static values = { text: String }

  connect() {
    const text = this.textValue
    if (!text) return

    this.chars = [...text]
    this.element.innerHTML = ""
    this.spans = this.chars.map(char => {
      const span = document.createElement("span")
      span.textContent = char
      span.className = "transition-colors duration-150"
      this.element.appendChild(span)
      return span
    })

    this.currentIndex = 0
    this.spans[0].classList.add("cursor-blink")
    this.scheduleNext()
  }

  scheduleNext() {
    const delay = 110 + Math.random() * 110 // 110〜220ms（人間らしい揺らぎ）
    this.timer = setTimeout(() => this.typeNext(), delay)
  }

  typeNext() {
    const span = this.spans[this.currentIndex]
    span.classList.remove("cursor-blink")
    span.classList.add("text-gray-400")
    this.currentIndex++

    if (this.currentIndex >= this.spans.length) {
      // 完走したら少し止めてからリセット
      this.timer = setTimeout(() => this.reset(), 2000)
      return
    }

    this.spans[this.currentIndex].classList.add("cursor-blink")
    this.scheduleNext()
  }

  reset() {
    this.spans.forEach(span => {
      span.classList.remove("text-gray-400", "cursor-blink")
    })
    this.currentIndex = 0
    this.spans[0].classList.add("cursor-blink")
    this.scheduleNext()
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
