import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlTab", "textTab", "urlContent", "textContent", "urlError", "urlInput"]

  showUrl() {
    // 表示する
    this.urlContentTarget.classList.remove("hidden")
    // アクティブなタブ → 青いアンダーライン + 青い文字
    this.urlTabTarget.classList.add("border-blue-500", "text-blue-600")
    this.urlTabTarget.classList.remove("border-transparent", "text-gray-400")
    // 非表示にする
    this.textContentTarget.classList.add("hidden")
    // 非アクティブなタブ → 透明アンダーライン + グレー文字
    this.textTabTarget.classList.add("border-transparent", "text-gray-400")
    this.textTabTarget.classList.remove("border-blue-500", "text-blue-600")
  }

  showText() {
        // 表示する
    this.textContentTarget.classList.remove("hidden")
    // アクティブなタブ → 青いアンダーライン + 青い文字
    this.textTabTarget.classList.add("border-blue-500", "text-blue-600")
    this.textTabTarget.classList.remove("border-transparent", "text-gray-400")
    // 非表示にする
    this.urlContentTarget.classList.add("hidden")
    // 非アクティブなタブ → 透明アンダーライン + グレー文字
    this.urlTabTarget.classList.add("border-transparent", "text-gray-400")
    this.urlTabTarget.classList.remove("border-blue-500", "text-blue-600")
  }

  async submitUrl(event) {
    event.preventDefault()
    this.urlErrorTarget.classList.add("hidden") // エラーを一旦消す

    const url = this.urlInputTarget.value.trim()
    if (url === "") {
      this.showUrlError("URLを入力してください")
      return
    }
    
    try {
      const parsed = new URL(url)
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
        this.showUrlError("正しいURL形式で入力してください（例：https://example.com）")
        return
      } 
    } catch {
      // new URL(url) が失敗した場合（完全に不正な文字列）
      this.showUrlError("正しいURL形式で入力してください（例：https://example.com）")
      return
    }

    const form = event.target
    const response = await fetch("/articles", {
      method: "POST",
      body: new FormData(form),
      redirect: "follow"
    })

    if (response.status === 429) {
      this.showUrlError("リクエストが多すぎます。しばらく時間をおいてから再度お試しください。")
      return
    } 

    if (response.redirected) {
      window.location.href = response.url
    }
  }


  showUrlError(message) {
    this.urlErrorTarget.textContent = message   // ← message を表示する
    this.urlErrorTarget.classList.remove("hidden")
  }
}