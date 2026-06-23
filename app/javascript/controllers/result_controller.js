import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["accuracy", "cpm", "wpm", "missCount", "elapsedTime", "saveSuccess", "saveFailed", "saveSkipped", "saveButton", "completedMessage", "endedMessage", "articleTitle", "articleTitleText", "copySuccess", "achievementBanners"]
    static values = { appUrl: String }

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
        const articleId = sessionStorage.getItem("article_id") || null
        if (articleTitle) {
            this.articleTitleTarget.classList.remove("hidden")
            this.articleTitleTextTarget.textContent = articleTitle
        }

        const body = this.buildResultBody(result, articleText, articleTitle, articleId)

        if (result.reason === "completed") {
            this.postResult(body, (data) => {
                if (data.status === "saved") {
                    this.saveSuccessTarget.classList.remove("hidden")
                    if (data.achievements?.length > 0) this.showAchievements(data.achievements)
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
                this.saveButtonTarget.classList.remove("hidden")
            } else {
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
        const articleId = sessionStorage.getItem("article_id") || null
        const body = this.buildResultBody(result, articleText, articleTitle, articleId)

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
        sessionStorage.removeItem("article_id")
        window.location.href = "/"
    }

    buildResultBody(result, articleText, articleTitle, articleId) {
        return {
            wpm: result.wpm,
            cpm: result.cpm,
            accuracy: result.accuracy,
            miss_count: result.missCount,
            elapsed_time: result.elapsedSeconds,
            article_text: articleText,
            article_title: articleTitle,
            correct_count: result.correctCount,
            article_id: articleId
        }
    }

    buildShareText() {
        const result = JSON.parse(sessionStorage.getItem("typing_result"))
        const appUrl = this.appUrlValue
        return `ReadTypingでCPM ${result.cpm}・正答率 ${result.accuracy}% を達成しました！\n${appUrl}`
    }

    shareOnX() {
        const text = this.buildShareText()
        const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}`
        window.open(url, "_blank", "noopener")
        this.recordShareAchievement()
    }

    recordShareAchievement() {
        const isLoggedIn = document.querySelector('meta[name="user-signed-in"]')?.content === "true"
        if (!isLoggedIn) return
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content
        fetch("/typing/results/share_achievement", {
            method: "POST",
            headers: { "X-CSRF-Token": csrfToken }
        }).catch(() => {})
    }

    showAchievements(achievements) {
        const container = this.achievementBannersTarget
        achievements.forEach(a => {
            const el = document.createElement("div")
            el.className = "flex justify-center"
            el.innerHTML = `
                <div class="inline-flex items-center gap-2 rounded-full bg-gray-800 border border-green-700 px-4 py-2 text-sm font-bold text-green-400">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.562.562 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                    </svg>
                    実績解除: ${a.name}
                </div>
            `
            container.appendChild(el)
        })
    }

    copyResult() {
        const text = this.buildShareText()
        navigator.clipboard.writeText(text).then(() => {
            this.copySuccessTarget.classList.remove("hidden")
            setTimeout(() => {
                this.copySuccessTarget.classList.add("hidden")
            }, 2000)
        })
    }
}