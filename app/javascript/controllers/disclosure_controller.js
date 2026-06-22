import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { storageKey: { type: String, default: "disclosure-open" } }

  connect() {
    const isOpen = localStorage.getItem(this.storageKeyValue) === "true"
    if (isOpen) {
      this.contentTarget.classList.remove("hidden")
      this.iconTarget.classList.add("rotate-180")
    }
  }

  toggle() {
    const isHidden = this.contentTarget.classList.toggle("hidden")
    this.iconTarget.classList.toggle("rotate-180")
    localStorage.setItem(this.storageKeyValue, String(!isHidden))
  }
}