import { Controller } from "@hotwired/stimulus"

const SPAN_BASE = "typing-char"
const KEY_CODE_TO_KEY = {
  "KeyA": "a", "KeyB": "b", "KeyC": "c", "KeyD": "d", "KeyE": "e", "KeyF": "f",
  "KeyG": "g", "KeyH": "h", "KeyI": "i", "KeyJ": "j", "KeyK": "k", "KeyL": "l",
  "KeyM": "m", "KeyN": "n", "KeyO": "o", "KeyP": "p", "KeyQ": "q", "KeyR": "r",
  "KeyS": "s", "KeyT": "t", "KeyU": "u", "KeyV": "v", "KeyW": "w", "KeyX": "x",
  "KeyY": "y", "KeyZ": "z",
  "Digit0": "0", "Digit1": "1", "Digit2": "2", "Digit3": "3", "Digit4": "4",
  "Digit5": "5", "Digit6": "6", "Digit7": "7", "Digit8": "8", "Digit9": "9",
  "Minus": "-", "Equal": "=", "BracketLeft": "[", "BracketRight": "]",
  "Backslash": "\\", "Semicolon": ";", "Quote": "'", "Comma": ",",
  "Period": ".", "Slash": "/", "Backquote": "`", "Space": " ",
  "Enter": "Enter", "ShiftLeft": "Shift", "ShiftRight": "ShiftRight"
}

export default class extends Controller {
  static targets = ["text", "input", "hint", "timer", "typedWindow", "progressBar", "progressText", "totalText", "title", "progressPercent", "keyboard", "skipModeButton", "missFlash"]

  connect() {
    const text = sessionStorage.getItem("typing_text")

    if (!text) {
      window.location.href = "/"
      return
    }

    const title = sessionStorage.getItem("article_title") || ""
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title
      if (title) {
        this.titleTarget.classList.remove("hidden")
      }
    }

    this.chars = [...text]
    this.totalTextTarget.textContent = this.chars.length
    this.renderText()
    this.resetTimer()
    this.initializePracticeState()

    this.skipModeEnabled = false
    this.skipNonTypableChars()
    this.updateCursor()
    this.inputTarget.focus()
  }

  handleKeydown(event) {
    const keyValue = KEY_CODE_TO_KEY[event.code] ?? event.key.toLowerCase()
    const pressedKeyEl = this.keyboardTarget.querySelector(`[data-key="${keyValue}"]`)
    if (pressedKeyEl) {
      pressedKeyEl.classList.add('!bg-gray-500', '!text-white', '!scale-90')
      // Shiftは長押し中ハイライトを維持し、keyupで解除する。
      const isShift = event.code === "ShiftLeft" || event.code === "ShiftRight"
      if (!isShift) {
        setTimeout(() => pressedKeyEl.classList.remove('!bg-gray-500', '!text-white', '!scale-90'), 120)
      }
    }

    if (event.isComposing) return

    if (event.key === "Enter") {
      event.preventDefault()
      return
    }

    if (event.key === "Backspace") {
      event.preventDefault()
      this.setTypedText(this.typedText.slice(0, -1))
      return
    }

    if (event.key.length !== 1) return

    if (event.key === " ") {
      event.preventDefault()
      if (this.skipModeEnabled && !this.isCompleted && this.isSkippableChar(this.chars[this.currentIndex])) {
        this.skipCurrentCharacter()
      }
      return
    }

    event.preventDefault()

    if (this.isCompleted) return

    const key = event.key
    const spans = this.textTarget.querySelectorAll("span")
    this.handleTypedCharacter(key, spans)
    this.setTypedText(this.typedText + key)
  }

  reset() {
    this.resetTimer()
    this.inputTarget.value = ""
    this.initializePracticeState()

    this.textTarget.querySelectorAll("span").forEach(span => {
      span.className = SPAN_BASE
    })

    this.skipNonTypableChars()
    this.updateCursor()
    this.hintTarget.classList.remove("hidden")
    this.inputTarget.focus()
  }

  initializePracticeState() {
    this.isStarted = false
    this.currentIndex = 0
    this.missCount = 0
    this.missIndices = []
    this.correctCount = 0
    this.isCompleted = false
    this.skippedCount = 0
    this.setTypedText("")
  }

  renderText() {
    this.textTarget.innerHTML = ""
    const fragment = document.createDocumentFragment()

    this.chars.forEach(char => {
      const span = document.createElement("span")
      span.textContent = char
      span.className = SPAN_BASE
      fragment.appendChild(span)
    })

    this.textTarget.appendChild(fragment)
  }

  setTypedText(text) {
    this.typedText = text
    this.typedWindowTarget.textContent = text
  }

  startPractice() {
    if (this.isStarted) return

    this.isStarted = true
    this.startTimer()
    this.hintTarget.classList.add("hidden")
  }

  handleTypedCharacter(char, spans) {
    this.startPractice()

    if (char === this.chars[this.currentIndex]) {
      this.markCurrentCharacterCorrect(spans)
    } else {
      this.markCurrentCharacterMissed(spans)
    }
  }

  markCurrentCharacterCorrect(spans) {
    spans[this.currentIndex].className = `${SPAN_BASE} text-gray-400`
    this.currentIndex++
    this.correctCount++
    this.skipNonTypableChars()
    this.updateCursor()

    if (this.currentIndex >= this.chars.length) this.completePractice()
  }

  markCurrentCharacterMissed(spans) {
    this.missCount++
    this.missIndices.push(this.currentIndex)
    const missSpan = spans[this.currentIndex]
    missSpan.className = `${SPAN_BASE} text-red-500 underline decoration-red-300 decoration-2`
    this.shakeChar(missSpan)
    this.flashMiss()
  }

  skipCurrentCharacter() {
    this.startPractice()
    const spans = this.textTarget.querySelectorAll("span")
    spans[this.currentIndex].className = `${SPAN_BASE} text-gray-300 line-through`
    this.skippedCount++
    this.currentIndex++
    this.skipNonTypableChars()
    this.updateCursor()

    if (this.currentIndex >= this.chars.length) this.completePractice()
  }

  completePractice() {
    this.isCompleted = true
    this.stopTimer()
    this.saveResult("completed")
    window.location.href = "/typing/result"
  }

  toggleSkipMode() {
    this.skipModeEnabled = !this.skipModeEnabled
    if (this.hasSkipModeButtonTarget) {
      this.skipModeButtonTarget.textContent = `スキップモード: ${this.skipModeEnabled ? "ON" : "OFF"}`
    }
  }

  // 現在の入力位置がスペースや改行の場合、入力済み扱いにして次の文字へ進める
  skipNonTypableChars() {
    while (
      this.currentIndex < this.chars.length &&
      (this.chars[this.currentIndex] === " " || this.chars[this.currentIndex] === "\n")
    ) {
      this.currentIndex++
    }
  }

  // スキップ対象かどうかを判定するメソッド
  isSkippableChar(char) {
    // 英数字・ひらがな・カタカナ・漢字はスキップ不可
    if (/[a-zA-Z0-9]/.test(char)) return false
    if (/[\u3040-\u309F]/.test(char)) return false  // ひらがな
    if (/[\u30FB\u30FC]/.test(char)) return true    // ・ー（カタカナ系記号）カタカナより先にスキップ
    if (/[\u30A0-\u30FF]/.test(char)) return false  // カタカナ
    if (/[\u4E00-\u9FFF]/.test(char)) return false  // 漢字（CJK統合）

    // ASCII記号・全角記号はスキップ可
    if (/[!-/:-@[-`{-~]/.test(char)) return true    // ASCII記号
    if (/[\uFF00-\uFFEF]/.test(char)) return true   // 全角英数・記号
    if (/[\u3000-\u303F]/.test(char)) return true   // CJK記号・句読点（。、・など）

    return false
  }

  //テキストエリア部分をクリックするとフォーカスが戻る
  focusInput() {
    this.inputTarget.focus()
  }

  // 現在地にカーソルを表示する
  updateCursor() {
    this.updateProgress()
    this.highlightNextKey()
    if (this.currentIndex >= this.chars.length) return // タイピング完了後はカーソルを表示しない
    const spans = this.textTarget.querySelectorAll("span")
    spans[this.currentIndex].className = `${SPAN_BASE} cursor-blink`

    // textareaの位置を更新する処理
    const rect = spans[this.currentIndex].getBoundingClientRect()
    this.inputTarget.style.top = `${rect.top + rect.height}px`
    this.inputTarget.style.left = `${rect.left}px`

    // スクロール追従
    const container = this.textTarget
    const containerRect = container.getBoundingClientRect()
    const spanRect = spans[this.currentIndex].getBoundingClientRect()

    const containerHeight = containerRect.height
    const cursorOffsetFromTop = spanRect.top - containerRect.top

    // カーソルが中央より少し下（55%）に入ったら、中央より少し上（45%）まで持ち上げる
    const triggerLine = containerHeight * 0.55
    const targetLine = containerHeight * 0.45

    if (cursorOffsetFromTop > triggerLine) {
      container.scrollTop += cursorOffsetFromTop - targetLine
    }

    // カーソルが画面上端より上に出た場合（リセット時など）の追従
    if (spanRect.top < containerRect.top) {
      container.scrollTop += spanRect.top - containerRect.top
    }
  }

  highlightNextKey() {
    // 前のハイライトをすべて消す
    this.keyboardTarget.querySelectorAll('[data-key]').forEach(el => {
      el.classList.remove('ring-2', 'ring-gray-800', 'brightness-75')
    })

    if (this.currentIndex >= this.chars.length) return

    const nextChar = this.chars[this.currentIndex]
    const keyValue = nextChar.toLowerCase()
    const keyEl = this.keyboardTarget.querySelector(`[data-key="${keyValue}"]`)

    if (keyEl) {
      keyEl.classList.add('ring-2', 'ring-gray-800', 'brightness-75')
    }
  }

  handleCompositionStart() {
    this.startPractice()
  }

  handleCompositionUpdate(event) {
    this.typedWindowTarget.textContent = event.data
  }

  // IME変換中のkeydownは判定しないため、確定した文字列をここで一文字ずつ処理する。
  handleCompositionEnd(event) {
    if (this.isCompleted) return

    const composed = [...event.data]
    const spans = this.textTarget.querySelectorAll("span")

    for (const char of composed) {
      if (this.isCompleted) break
      this.handleTypedCharacter(char, spans)
    }
    // 確定後にtextareaを空にし、次のIME変換を先頭から始められるようにする。
    this.inputTarget.value = ""
    this.typedWindowTarget.textContent = ""
  }

  // タイマーを開始する
  startTimer() {
    if (this.timerId) return

    this.startTime = performance.now()
    this.elapsedMilliseconds = 0
    this.elapsedSeconds = 0

    this.updateTimer()

    this.timerId = setInterval(() => {
      this.updateTimer()
    }, 100)
  }

  // 経過時間を計算して、画面の表示を更新する
  updateTimer() {
    this.elapsedMilliseconds = performance.now() - this.startTime
    this.elapsedSeconds = Math.floor(this.elapsedMilliseconds / 1000)

    const minutes = Math.floor(this.elapsedSeconds / 60).toString().padStart(2, "0")
    const secs = (this.elapsedSeconds % 60).toString().padStart(2, "0")

    this.timerTarget.textContent = `${minutes}:${secs}`
  }

  // 動いているタイマーを停止する
  stopTimer() {
    if (!this.timerId) return

    this.updateTimer()
    clearInterval(this.timerId)
    this.timerId = null
  }

  // タイマーを停止して、表示と値を初期状態に戻す
  resetTimer() {
    this.stopTimer()

    this.startTime = null
    this.elapsedMilliseconds = 0
    this.elapsedSeconds = 0
    this.timerTarget.textContent = "00:00"
  }

  // 画面遷移などでコントローラが外れたときにタイマーを止める
  disconnect() {
    this.stopTimer()
  }

  // 正答率 = correctCount / (correctCount + missCount) * 100
  calculateAccuracy() {
    const total = this.correctCount + this.missCount
    if (total === 0) return 0
    return Math.round((this.correctCount / total) * 100)
  }

  // 文字/分 (CPM) = correctCount / (elapsedSeconds / 60)
  calculateCpm() {
    if (this.elapsedSeconds === 0) return 0
    return Math.round(this.correctCount / (this.elapsedSeconds / 60))
  }

  // WPM目安（補助指標） WPM = CPM / 5
  calculateWpm() {
    return Math.round(this.calculateCpm() / 5)
  }

  // 完了時に結果をsessionStorageへ保存する
  saveResult(reason) {
    const result = {
      correctCount: this.correctCount,
      missCount: this.missCount,
      missIndices: this.missIndices,
      skippedCount: this.skippedCount,
      elapsedSeconds: this.elapsedSeconds,
      accuracy: this.calculateAccuracy(),
      cpm: this.calculateCpm(),
      wpm: this.calculateWpm(),
      reason: reason
    }
    sessionStorage.setItem("typing_result", JSON.stringify(result))
    sessionStorage.setItem("result_from_typing", "true")
  }

  // 途中で終了しても結果画面へ
  endPractice() {
    this.stopTimer()
    this.saveResult("ended")
    window.location.href = "/typing/result"
  }

  // Shiftキーの離鍵を検知してハイライトを解除する
  handleKeyup(event) {
    if (event.code !== "ShiftLeft" && event.code !== "ShiftRight") return
    const keyValue = event.code === "ShiftLeft" ? "Shift" : "ShiftRight"
    const keyEl = this.keyboardTarget.querySelector(`[data-key="${keyValue}"]`)
    if (keyEl) {
      keyEl.classList.remove('!bg-gray-500', '!text-white', '!scale-90')
    }
  }

  // ミス文字を一瞬シェイクさせる
  shakeChar(span) {
    span.classList.remove('char-shake')
    void span.offsetWidth // アニメーションを再生し直すための強制リフロー
    span.classList.add('char-shake')
    clearTimeout(this._shakeTimer)
    this._shakeTimer = setTimeout(() => span.classList.remove('char-shake'), 220)
  }

  // ミス時に画面全体を一瞬だけ赤くフラッシュさせる
  flashMiss() {
    if (!this.hasMissFlashTarget) return
    const flash = this.missFlashTarget
    flash.classList.remove('opacity-0')
    flash.classList.add('opacity-100')
    clearTimeout(this._missFlashTimer)
    this._missFlashTimer = setTimeout(() => {
      flash.classList.remove('opacity-100')
      flash.classList.add('opacity-0')
    }, 100)
  }

  // 進捗
  updateProgress(){
    const total = this.chars.length
    if (total === 0) return
    const percent = Math.round((this.currentIndex / total) * 100)
    this.progressBarTarget.style.width = `${percent}%`
    this.progressTextTarget.textContent = this.currentIndex
    if (this.hasProgressPercentTarget) {
      this.progressPercentTarget.textContent = percent
    }
  }
}
