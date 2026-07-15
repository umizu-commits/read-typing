import { Controller } from "@hotwired/stimulus"

const GENERIC_FETCH_ERROR = "記事の取得に失敗しました。URLを確認するか、しばらく時間をおいてから再度お試しください。"
const RATE_LIMIT_ERROR = "リクエストが多すぎます。しばらく時間をおいてから再度お試しください。"

export default class extends Controller {
  static targets = ["urlTab", "textTab", "urlContent", "textContent", "urlError", "urlInput"]

  showUrl() {
    this.setTabState(this.urlTabTarget, this.urlContentTarget, true)
    this.setTabState(this.textTabTarget, this.textContentTarget, false)
  }

  showText() {
    this.setTabState(this.textTabTarget, this.textContentTarget, true)
    this.setTabState(this.urlTabTarget, this.urlContentTarget, false)
  }

  async submitUrl(event) {
    event.preventDefault()
    this.hideUrlError()
    if (!this.validateUrl()) return

    try {
      const response = await this.postArticleForm(new FormData(event.target))
      this.handleArticleRedirect(response, "/typing", () => this.clearStoredArticleMetadata())
    } catch {
      this.showUrlError(GENERIC_FETCH_ERROR)
    }
  }

  async saveOnlyUrl(event) {
    this.hideUrlError()
    if (!this.validateUrl()) return

    const form = event.target.closest("form")
    const formData = new FormData(form)
    formData.append("save_only", "true")

    try {
      const response = await this.postArticleForm(formData)
      this.handleArticleRedirect(response, "/articles")
    } catch {
      this.showUrlError(GENERIC_FETCH_ERROR)
    }
  }

  async fetchWithoutSave() {
    this.hideUrlError()

    const url = this.validateUrl()
    if (!url) return

    try {
      const response = await fetch("/articles/fetch", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ url })
      })

      if (!response.ok) {
        await this.showFetchError(response)
        return
      }

      const data = await response.json()
      sessionStorage.setItem("typing_text", data.body)
      sessionStorage.setItem("article_title", data.title || "")
      sessionStorage.removeItem("article_id")
      window.location.href = "/typing"
    } catch {
      this.showUrlError(GENERIC_FETCH_ERROR)
    }
  }

  setTabState(tab, content, active) {
    content.classList.toggle("hidden", !active)
    tab.classList.toggle("border-green-500", active)
    tab.classList.toggle("text-green-500", active)
    tab.classList.toggle("border-transparent", !active)
    tab.classList.toggle("text-gray-500", !active)
  }

  async postArticleForm(formData) {
    return fetch("/articles", {
      method: "POST",
      body: formData,
      redirect: "follow"
    })
  }

  handleArticleRedirect(response, expectedPath, beforeRedirect = () => {}) {
    if (response.status === 429) {
      this.showUrlError(RATE_LIMIT_ERROR)
      return
    }

    if (!response.redirected || !new URL(response.url).pathname.startsWith(expectedPath)) {
      this.showUrlError(GENERIC_FETCH_ERROR)
      return
    }

    beforeRedirect()
    window.location.href = response.url
  }

  async showFetchError(response) {
    try {
      const data = await response.json()
      this.showUrlError(data.error || GENERIC_FETCH_ERROR)
    } catch {
      this.showUrlError(GENERIC_FETCH_ERROR)
    }
  }

  clearStoredArticleMetadata() {
    sessionStorage.removeItem("article_title")
    sessionStorage.removeItem("article_id")
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  // URL の空・形式を確認し、有効な URL 文字列を返す。無効なら null を返す。
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

  hideUrlError() {
    this.urlErrorTarget.classList.add("hidden")
  }

  showUrlError(message) {
    this.urlErrorTarget.textContent = message
    this.urlErrorTarget.classList.remove("hidden")
  }
}
