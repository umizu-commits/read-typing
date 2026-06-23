import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlTab", "textTab", "urlContent", "textContent", "urlError", "urlInput"]

  showUrl() {
    this.urlContentTarget.classList.remove("hidden")
    this.urlTabTarget.classList.add("border-green-500", "text-green-500")
    this.urlTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.textContentTarget.classList.add("hidden")
    this.textTabTarget.classList.add("border-transparent", "text-gray-500")
    this.textTabTarget.classList.remove("border-green-500", "text-green-500")
  }

  showText() {
    this.textContentTarget.classList.remove("hidden")
    this.textTabTarget.classList.add("border-green-500", "text-green-500")
    this.textTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.urlContentTarget.classList.add("hidden")
    this.urlTabTarget.classList.add("border-transparent", "text-gray-500")
    this.urlTabTarget.classList.remove("border-green-500", "text-green-500")
  }

  async submitUrl(event) {
    event.preventDefault()
    this.urlErrorTarget.classList.add("hidden")

    const url = this.validateUrl()
    if (!url) return

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
      const path = new URL(response.url).pathname
      if (path.startsWith("/typing")) {
        sessionStorage.removeItem("article_title")
        window.location.href = response.url
      } else {
        this.showUrlError("記事の取得に失敗しました。URLを確認するか、しばらく時間をおいてから再度お試しください。")
      }
    }
  }

  async saveOnlyUrl(event) {
    this.urlErrorTarget.classList.add("hidden")

    const url = this.validateUrl()
    if (!url) return

    const formEl = event.target.closest("form")
    const formData = new FormData(formEl)
    formData.append("save_only", "true")

    const response = await fetch("/articles", {
      method: "POST",
      body: formData,
      redirect: "follow"
    })

    if (response.status === 429) {
      this.showUrlError("リクエストが多すぎます。しばらく時間をおいてから再度お試しください。")
      return
    }

    if (response.redirected) {
      const path = new URL(response.url).pathname
      if (path.startsWith("/articles")) {
        window.location.href = response.url
      } else {
        this.showUrlError("記事の取得に失敗しました。URLを確認するか、しばらく時間をおいてから再度お試しください。")
      }
    }
  }

  async fetchWithoutSave(event) {
    this.urlErrorTarget.classList.add("hidden")

    const url = this.validateUrl()
    if (!url) return

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

    const data = await response.json()
    sessionStorage.setItem("typing_text", data.body)
    sessionStorage.setItem("article_title", data.title || "")
    window.location.href = "/typing"
  }

  // URL の空チェック・形式チェックを行い、有効な URL 文字列を返す。無効なら null を返す。
  validateUrl() {
    const url = this.urlInputTarget.value.trim()
    if (url === "") {
      this.showUrlError("URLを入力してください")
      return null
    }
    try {
      const parsed = new URL(url)
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
        this.showUrlError("正しいURL形式で入力してください（例：https://example.com）")
        return null
      }
      return url
    } catch {
      this.showUrlError("正しいURL形式で入力してください（例：https://example.com）")
      return null
    }
  }

  showUrlError(message) {
    this.urlErrorTarget.textContent = message
    this.urlErrorTarget.classList.remove("hidden")
  }
}
