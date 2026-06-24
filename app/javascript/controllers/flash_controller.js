import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージをスライドイン表示し、一定時間後に自動消失させる。
// ピル本体（data-flash-target="pill"）に opacity/translate のトランジションを掛ける。
export default class extends Controller {
  static targets = ["pill"]
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    if (!this.hasPillTarget) return
    // 次フレームでスライドイン
    requestAnimationFrame(() => {
      this.pillTarget.classList.remove("opacity-0", "-translate-y-2")
      this.pillTarget.classList.add("opacity-100", "translate-y-0")
    })
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    }
  }

  dismiss() {
    clearTimeout(this.timer)
    if (this.hasPillTarget) {
      this.pillTarget.classList.remove("opacity-100", "translate-y-0")
      this.pillTarget.classList.add("opacity-0", "-translate-y-2")
    }
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
