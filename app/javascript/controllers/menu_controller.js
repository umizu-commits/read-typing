import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "openIcon", "closeIcon"]

  connect() {
    this._onDocClick = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    document.addEventListener("click", this._onDocClick)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick)
  }

  toggle() {
    const isHidden = this.panelTarget.classList.toggle("hidden")
    this.openIconTarget.classList.toggle("hidden", !isHidden)
    this.closeIconTarget.classList.toggle("hidden", isHidden)
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }
}
