import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
static targets = ["text", "error"]

submit(event) {
    event.preventDefault()

    const text = this.textTarget.value.trim()

    if (text === "") {
    this.showError("テキストを入力してください")
    return
    }

    if (text.length < 50) {
    this.showError("50文字以上のテキストを入力してください")
    return
    }

    if (text.length > 10000) {
    this.showError("10,000文字以内のテキストを入力してください")
    return
    }

    sessionStorage.setItem("typing_text", text)
    window.location.href = "/typing"
}

showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
}
}