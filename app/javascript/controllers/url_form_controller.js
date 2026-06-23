import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlTab", "textTab", "urlContent", "textContent", "urlError", "urlInput"]

  showUrl() {
    // 表示する
    this.urlContentTarget.classList.remove("hidden")
    // アクティブなタブ → 青いアンダーライン + 青い文字
    this.urlTabTarget.classList.add("border-green-500", "text-green-500")
    this.urlTabTarget.classList.remove("border-transparent", "text-gray-500")
    // 非表示にする
    this.textContentTarget.classList.add("hidden")
    // 非アクティブなタブ → 透明アンダーライン + グレー文字
    this.textTabTarget.classList.add("border-transparent", "text-gray-500")
    this.textTabTarget.classList.remove("border-green-500", "text-green-500")
  }

  showText() {
        // 表示する
    this.textContentTarget.classList.remove("hidden")
    // アクティブなタブ → 青いアンダーライン + 青い文字
    this.textTabTarget.classList.add("border-green-500", "text-green-500")
    this.textTabTarget.classList.remove("border-transparent", "text-gray-500")
    // 非表示にする
    this.urlContentTarget.classList.add("hidden")
    // 非アクティブなタブ → 透明アンダーライン + グレー文字
    this.urlTabTarget.classList.add("border-transparent", "text-gray-500")
    this.urlTabTarget.classList.remove("border-green-500", "text-green-500")
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
      sessionStorage.removeItem("article_title")
      window.location.href = response.url
    }
  }


  showUrlError(message) {
    this.urlErrorTarget.textContent = message   // ← message を表示する
    this.urlErrorTarget.classList.remove("hidden")
  }

  async fetchWithoutSave(event) {
    this.urlErrorTarget.classList.add("hidden")

    // URL バリデーション（submitUrl と同じ）
    const url = this.urlInputTarget.value.trim()
    if (url === "") { this.showUrlError("URLを入力してください"); return }
    try {
      const parsed = new URL(url)
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
        this.showUrlError("正しいURL形式で入力してください（例：https://example.com）"); return
      }
    } catch {
      this.showUrlError("正しいURL形式で入力してください（例：https://example.com）"); return
    }

    // POST /articles/fetch へ JSON で送信
    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const response = await fetch("/articles/fetch", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ url })
    })

    if (!response.ok) {
      try {
        const data = await response.json()
        this.showUrlError(data.error || "記事の取得に失敗しました")
      } catch {
        this.showUrlError("記事の取得に失敗しました")
      }
      return
    }

    // sessionStorage に保存して /typing へ遷移
    const data = await response.json()
    sessionStorage.setItem("typing_text", data.body)
    sessionStorage.setItem("article_title", data.title || "")
    window.location.href = "/typing"
  }
}