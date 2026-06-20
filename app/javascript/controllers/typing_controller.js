import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "input","hint" ,"timer", "typedWindow", "progressBar", "progressText", "totalText", "title","progressPercent"]

  connect() {
    const text = sessionStorage.getItem("typing_text")

    if (!text) {
      window.location.href = "/"
      return
    }

    // article_titleを読み取り、タイトル表示エリアに反映
    const title = sessionStorage.getItem("article_title") || ""
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title
      if (title) {
        this.titleTarget.classList.remove("hidden")
      }
    }

    this.chars = [...text] // handleInput() の中でも元のテキストを参照できるよう、this.chars に保存
    this.totalTextTarget.textContent = this.chars.length
    this.inputTarget.focus() // ページ表示と同時にフォーカスを当てる

    // 1文字ずつ span に変換して表示する
    this.textTarget.innerHTML = ""

    const fragment = document.createDocumentFragment()

    this.chars.forEach(char => {
      const span = document.createElement("span")
      span.textContent = char // textContent は HTML として解釈しない
      fragment.appendChild(span)
    })

    this.textTarget.appendChild(fragment)

    // 最初の入力でタイマーを開始するため、開始状態を未開始にしておく
    this.isStarted = false
    // タイピング開始時は先頭の文字から判定する
    this.currentIndex = 0

    // ミスのカウント
    this.missCount = 0

    // 正解数のカウント
    this.correctCount = 0

    // タイピング完了のフラグ
    this.isCompleted = false

    // タイピング中の文字（入力ウィンドウに表示）
    this.typedText = ""

    // タイマー用の状態
    this.timerId = null
    this.startTime = null
    this.elapsedMilliseconds = 0
    this.elapsedSeconds = 0
    this.timerTarget.textContent = "00:00"


    this.skipNonTypableChars()

    //現在地にカーソルを表示する
    this.updateCursor()
  }

  // キーが押されたときの処理
  handleKeydown(event) {

    // IME変換中はすべてスキップ
    if (event.isComposing) return

    // Enterキーを無効にする部分
    if (event.key === "Enter") {
      event.preventDefault()
      return
    }

    // BackSpaceキーを無効にする
    if (event.key === "Backspace") {
      event.preventDefault()
      this.typedText = this.typedText.slice(0, -1)
      this.typedWindowTarget.textContent = this.typedText
      return
    }

    // ShiftやCtrlなどを無視する部分
    if (event.key.length !== 1) return
    //スペースキーは無視する
    if (event.key === " ") return

    // textareaへの文字蓄積を防ぐ
    event.preventDefault() // デフォルトのキー入力を無効にする

    if (this.isCompleted) return

    // 最初の入力時だけ、開始済みにしてヒントを非表示にする
    if (!this.isStarted) {
      this.isStarted = true
      this.startTimer()
      this.hintTarget.classList.add("hidden")
    }

    // 入力されたキーと期待される文字を取得する部分
    const key = event.key // event.key は押されたキーの文字を返す（例: "a": Key A)
    const expectedChar = this.chars[this.currentIndex] // 本来入力してほしい文字

    // 入力されたキーが期待される文字と一致する場合、次の文字に進む
    const spans = this.textTarget.querySelectorAll("span")
    if (key === expectedChar) {
      spans[this.currentIndex].className = "text-gray-400"
      this.currentIndex++
      this.correctCount++
      this.skipNonTypableChars()
      this.updateCursor()

      if (this.currentIndex >= this.chars.length) {
        this.isCompleted = true // タイピング完了のフラグを立てる
        this.stopTimer()
        this.saveResult("completed")
        window.location.href = "/typing/result" // 完了時に自動で結果画面へ遷移する
      }
    } else {
      this.missCount++ // ミスをカウントする
      spans[this.currentIndex].className = "text-red-500 underline decoration-red-300 decoration-2"
    }
    this.typedText += key // 入力されたキーをTypedTextに追記
    this.typedWindowTarget.textContent = this.typedText // 入力ウィンドウに反映
  }

  // リセットボタンのイベントハンドラ
  reset() {
    this.resetTimer()

    this.inputTarget.value = ""
    this.isStarted = false
    this.currentIndex = 0
    this.missCount = 0
    this.correctCount = 0
    this.isCompleted = false

    this.textTarget.querySelectorAll("span").forEach(span => {
      span.className = ""
    })

    this.skipNonTypableChars()
    this.updateCursor()
    this.hintTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.updateProgress()
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

  //テキストエリア部分をクリックするとフォーカスが戻る
  focusInput() {
    this.inputTarget.focus()
  }

  // 現在地にカーソルを表示する
  updateCursor() {
    this.updateProgress()
    if (this.currentIndex >= this.chars.length) return // タイピング完了後はカーソルを表示しない
    const spans = this.textTarget.querySelectorAll("span")
    spans[this.currentIndex].className = "cursor-blink"

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


  handleCompositionStart() {
    if (this.isStarted) return
    this.isStarted = true
    this.startTimer()
    this.hintTarget.classList.add("hidden")
  }


  handleCompositionUpdate(event) {
    // 変換中の文字に合わせて文字を表示する
    this.typedWindowTarget.textContent = event.data
  }

  // IMEの確定時に呼ばれる
  // handleKeydownは isComposing 中にスキップされるため、日本語入力の判定はこちらで処理する
  handleCompositionEnd(event) {
    if (this.isCompleted) return

    const composed = [...event.data]
    const spans = this.textTarget.querySelectorAll("span")

    for (const char of composed) {
      if (this.isCompleted) break

      if (!this.isStarted) {
        this.isStarted = true
        this.startTimer()
        this.hintTarget.classList.add("hidden")
      }

      if (char === this.chars[this.currentIndex]) {
        spans[this.currentIndex].className = "text-gray-400"
        this.currentIndex++
        this.correctCount++
        this.skipNonTypableChars()
        this.updateCursor()

        if (this.currentIndex >= this.chars.length) {
          this.isCompleted = true
          this.stopTimer()
          this.saveResult("completed")
          window.location.href = "/typing/result"
        }
      } else {
        this.missCount++
        spans[this.currentIndex].className = "text-red-500 underline decoration-red-300 decoration-2"
      }
    }
    this.inputTarget.value = "" // 1回の変換確定後にtextareaをクリアすることで、次の変換開始時にカーソルが先頭に戻る
    this.typedWindowTarget.textContent = "" // 確定時にクリア
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