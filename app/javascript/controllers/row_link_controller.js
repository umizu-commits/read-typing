import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  visit() {
    window.location.href = this.urlValue
  }
}