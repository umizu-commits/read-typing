import { Controller } from "@hotwired/stimulus"

// Turbo のネイティブ confirm を置き換える自作モーダル。
// application.js で Turbo.setConfirmMethod に登録された関数からカスタムイベント "confirm:open"
// が発火されるので、それを受けて表示・閉じる。
export default class extends Controller {
  static targets = ["panel", "message"]

  connect() {
    this.handleOpen = (event) => this.show(event.detail.message, event.detail.resolve)
    document.addEventListener("confirm:open", this.handleOpen)
  }

  disconnect() {
    document.removeEventListener("confirm:open", this.handleOpen)
  }

  show(message, resolve) {
    this.resolveFn = resolve
    this.messageTarget.textContent = message
    this.element.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("opacity-0", "scale-95")
      this.panelTarget.classList.add("opacity-100", "scale-100")
    })
  }

  confirm() {
    if (this.resolveFn) this.resolveFn(true)
    this.hide()
  }

  cancel() {
    if (this.resolveFn) this.resolveFn(false)
    this.hide()
  }

  // 背景クリックで閉じる
  backdropClick(event) {
    if (event.target === this.element) this.cancel()
  }

  // Escキーで閉じる
  keydown(event) {
    if (event.key === "Escape") this.cancel()
  }

  hide() {
    this.panelTarget.classList.remove("opacity-100", "scale-100")
    this.panelTarget.classList.add("opacity-0", "scale-95")
    setTimeout(() => {
      this.element.classList.add("hidden")
      this.resolveFn = null
    }, 150)
  }
}
