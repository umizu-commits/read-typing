import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal"]

    open() {
        this.modalTarget.classList.remove("hidden")
        document.body.style.overflow = "hidden"
    }

    close() {
        this.modalTarget.classList.add("hidden")
        document.body.style.overflow = ""
    }

    // 背景クリックで閉じる（モーダル本体クリックでは閉じない）
    backdropClick(event) {
        if (event.target === this.modalTarget) this.close()
    }

    // Escキーで閉じる（モーダル表示中のみ）
    keydown(event) {
        if (event.key !== "Escape") return
        if (this.modalTarget.classList.contains("hidden")) return
        this.close()
    }
}
