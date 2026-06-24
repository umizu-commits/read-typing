import { Controller } from "@hotwired/stimulus"

// 汎用タブ切替コントローラ
// data-tabs-target="tab" と data-tabs-target="panel" を data-tab="..." の同じ値で紐付ける
export default class extends Controller {
  static targets = ["tab", "panel"]

  show(event) {
    const id = event.currentTarget.dataset.tab
    if (!id) return

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === id
      tab.classList.toggle("border-green-500", isActive)
      tab.classList.toggle("text-green-500", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("text-gray-500", !isActive)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.tab !== id)
    })
  }
}
