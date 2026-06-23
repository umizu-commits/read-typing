import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "error", "clearButton", "title", "counter", "category", "tagNames"]

  submit(event) {
    event.preventDefault()

    const text = this.validateText()
    if (!text) return

    sessionStorage.setItem("typing_text", text)
    sessionStorage.setItem("article_title", this.titleTarget.value.trim())
    window.location.href = "/typing"
  }

  async saveOnly() {
    const text = this.validateText()
    if (!text) return

    await this.submitArticleForm(text, { save_only: "true" })
  }

  async submitWithSave(event) {
    const text = this.validateText()
    if (!text) return

    await this.submitArticleForm(text)
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clear() {
    const confirmed = window.confirm("入力した文章を削除しますか？この操作を行うと元に戻せません。")
    if (!confirmed) return

    this.textTarget.value = ""
    this.clearButtonTarget.disabled = true
    this.errorTarget.classList.add("hidden")
  }

  toggleClearButton() {
    const text = this.textTarget.value.trim()
    this.clearButtonTarget.disabled = text === ""

    if (this.hasCounterTarget) {
      const count = text.length
      this.counterTarget.textContent = `${count.toLocaleString()} / 10,000 文字`
      this.counterTarget.classList.toggle("text-red-500", count > 10000)
      this.counterTarget.classList.toggle("text-gray-400", count <= 10000)
    }
  }

  // テキストの空・文字数チェックを行い、有効なテキストを返す。無効なら null を返す。
  validateText() {
    const text = this.textTarget.value.trim()
    if (text === "") {
      this.showError("テキストを入力してください")
      return null
    }
    if (text.length < 50) {
      this.showError("50文字以上のテキストを入力してください")
      return null
    }
    if (text.length > 10000) {
      this.showError("10,000文字以内のテキストを入力してください")
      return null
    }
    return text
  }

  // POST /articles に source_type: "text" で送信する
  async submitArticleForm(text, extraFields = {}) {
    const formData = new FormData()
    const fields = {
      authenticity_token: document.querySelector("meta[name='csrf-token']").content,
      source_type: "text",
      body: text,
      title: this.titleTarget.value.trim(),
      category: this.categoryTarget.value,
      tag_names: this.tagNamesTarget.value,
      ...extraFields
    }
    Object.entries(fields).forEach(([name, value]) => formData.append(name, value))

    const response = await fetch("/articles", {
      method: "POST",
      body: formData,
      redirect: "follow"
    })

    if (response.status === 429) {
      this.showError("リクエストが多すぎます。しばらく時間をおいてから再度お試しください。")
      return
    }

    if (response.redirected) {
      window.location.href = response.url
    }
  }
}
