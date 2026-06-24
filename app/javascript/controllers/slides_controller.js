import { Controller } from "@hotwired/stimulus"

// チュートリアル等のスライド表示制御。前/次/ドット直接ジャンプに対応。
export default class extends Controller {
  static targets = ["slide", "dot", "prev", "next", "counter"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.update()
  }

  next() {
    if (this.indexValue < this.slideTargets.length - 1) {
      this.indexValue++
      this.update()
    }
  }

  prev() {
    if (this.indexValue > 0) {
      this.indexValue--
      this.update()
    }
  }

  goto(event) {
    const i = parseInt(event.currentTarget.dataset.index, 10)
    if (Number.isNaN(i)) return
    this.indexValue = i
    this.update()
  }

  update() {
    const total = this.slideTargets.length
    const current = this.indexValue
    const atStart = current === 0
    const atEnd = current === total - 1

    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("hidden", i !== current)
    })

    if (this.hasDotTarget) {
      this.dotTargets.forEach((dot, i) => {
        const active = i === current
        dot.classList.toggle("bg-green-500", active)
        dot.classList.toggle("bg-gray-700", !active)
        dot.classList.toggle("w-4", active)
        dot.classList.toggle("w-2", !active)
      })
    }

    if (this.hasPrevTarget) {
      this.prevTarget.disabled = atStart
      this.prevTarget.classList.toggle("opacity-30", atStart)
      this.prevTarget.classList.toggle("cursor-not-allowed", atStart)
    }

    if (this.hasNextTarget) {
      this.nextTarget.disabled = atEnd
      this.nextTarget.classList.toggle("opacity-30", atEnd)
      this.nextTarget.classList.toggle("cursor-not-allowed", atEnd)
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${current + 1} / ${total}`
    }
  }
}
