import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
static targets = ["text", "error", "clearButton", "title", "counter"]

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
    const title = this.titleTarget.value.trim()
    sessionStorage.setItem("article_title", title)
    window.location.href = "/typing"
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

toggleClearButton(){
    const text = this.textTarget.value.trim()
    this.clearButtonTarget.disabled = text === ""

    if (this.hasCounterTarget) {
        const count = text.length
        this.counterTarget.textContent = `${count.toLocaleString()} / 10,000 文字`
        this.counterTarget.classList.toggle("text-red-500", count > 10000)
        this.counterTarget.classList.toggle("text-gray-400", count <= 10000)
    }
}
}