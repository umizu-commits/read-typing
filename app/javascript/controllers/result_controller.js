import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["accuracy", "cpm", "wpm", "missCount", "elapsedTime", "saveSuccess", "saveFailed", "saveSkipped", "saveButton", "completedMessage", "endedMessage", "articleTitle", "articleTitleText"]

    connect() {
        const raw = sessionStorage.getItem("typing_result")

        // sessionStorageに結果がない場合はトップページに戻す（直接アクセス防止）
        if (!raw) {
            window.location.href = "/"
            return
        }

        // タイピング完了後の初回アクセス以外はリダイレクト（直接アクセス防止）
        const fromTyping = sessionStorage.getItem("result_from_typing")
        if (!fromTyping) {
            window.location.href = "/"
            return
        }

        sessionStorage.removeItem("result_from_typing") // フラグは初回のみ使用

        const result = JSON.parse(raw)

        this.accuracyTarget.textContent = `${result.accuracy}%`
        this.cpmTarget.textContent = result.cpm
        this.wpmTarget.textContent = result.wpm
        this.missCountTarget.textContent = result.missCount
        this.elapsedTimeTarget.textContent = this.formatTime(result.elapsedSeconds)

        const articleText = sessionStorage.getItem("typing_text")
        
        const articleTitle = sessionStorage.getItem("article_title") || ""
        if (articleTitle) {
            this.articleTitleTarget.classList.remove("hidden")
            this.articleTitleTextTarget.textContent = articleTitle
        }

        if (result.reason === "completed") {
            const body = { wpm: result.wpm, cpm: result.cpm, accuracy: result.accuracy, miss_count: result.missCount, elapsed_time: result.elapsedSeconds, article_text: articleText, article_title: articleTitle }
            this.postResult(body, (data) => {
                if (data.status === "saved") {
                    this.saveSuccessTarget.classList.remove("hidden")
                } else if (data.status === "skipped") {
                    this.saveSkippedTarget.classList.remove("hidden")
                } else {
                    this.saveFailedTarget.classList.remove("hidden")
                } 
            })

        } else if (result.reason === "ended") {
            // 途中終了時は保存ボタンを表示してユーザーの判断に委ねる
            const isLoggedIn = document.querySelector('meta[name="user-signed-in"]')?.content === "true"
            
            if (isLoggedIn) {
              this.saveButtonTarget.classList.remove("hidden") // 保存ボタンを表示
            } else {
                const body = { wpm: result.wpm, cpm: result.cpm, accuracy: result.accuracy, miss_count: result.missCount, elapsed_time: result.elapsedSeconds, article_text: articleText, article_title: articleTitle }
                this.postResult(body, (data) => {
                    if (data.status === "skipped") {
                        this.saveSkippedTarget.classList.remove("hidden")
                    }
                })
            }
            this.completedMessageTarget.classList.add("hidden")
            this.endedMessageTarget.classList.remove("hidden")
        }
    }

    postResult(body, onSuccess) {
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content
        fetch("/typing/results", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken
            },
            body: JSON.stringify(body)
        })
        .then(res => res.json())
        .then(data => onSuccess(data))
        .catch(() => {
            this.saveFailedTarget.classList.remove("hidden")
        })
    }

    formatTime(seconds) {
        const m = Math.floor(seconds / 60).toString().padStart(2, "0")
        const s = (seconds % 60).toString().padStart(2, "0")
        return `${m}:${s}`
    }

    // 途中終了時に保存するかの選択で「保存する」を選んだ場合の処理
    saveManually() {
        const articleText = sessionStorage.getItem("typing_text")
        const articleTitle = sessionStorage.getItem("article_title") || ""
        const result = JSON.parse(sessionStorage.getItem("typing_result"))
        const body = { wpm: result.wpm, cpm: result.cpm, accuracy: result.accuracy, miss_count: result.missCount, elapsed_time: result.elapsedSeconds, article_text: articleText, article_title: articleTitle }

        this.postResult(body, (data) => {
            if (data.status === "saved") {
                this.saveSuccessTarget.classList.remove("hidden")
                this.saveButtonTarget.classList.add("hidden")
            } else {
                this.saveFailedTarget.classList.remove("hidden")
            }  
        })  
    }

    // sessionStorageの削除を行ってから、TOPページに遷移する
    goToTop() {
        sessionStorage.removeItem("typing_text")
        sessionStorage.removeItem("typing_result")
        sessionStorage.removeItem("article_title")
        window.location.href = "/"
    }
}