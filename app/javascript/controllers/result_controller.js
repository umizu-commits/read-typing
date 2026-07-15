import { Controller } from "@hotwired/stimulus"
import confetti from "canvas-confetti"

export default class extends Controller {
    static targets = ["accuracy", "cpm", "wpm", "missCount", "elapsedTime", "saveSuccess", "saveFailed", "saveSkipped", "saveButton", "completedMessage", "endedMessage", "articleTitle", "articleTitleText", "copySuccess", "achievementBanners", "rankLetter", "missHeatmap", "heatmapBody"]
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

        this.animateNumber(this.accuracyTarget, result.accuracy, { suffix: "%" })
        this.animateNumber(this.cpmTarget, result.cpm)
        this.animateNumber(this.wpmTarget, result.wpm)
        this.animateNumber(this.missCountTarget, result.missCount)
        this.animateNumber(this.elapsedTimeTarget, result.elapsedSeconds, {
            formatter: (v) => this.formatTime(Math.round(v))
        })

        this.applyRank(result)

        const { articleText, articleTitle, articleId } = this.articleContext()
        if (articleTitle) {
            this.articleTitleTarget.classList.remove("hidden")
            this.articleTitleTextTarget.textContent = articleTitle
        }

        this.renderHeatmap(articleText, result.missIndices)

        const body = this.buildResultBody(result, articleText, articleTitle, articleId)

        if (result.reason === "completed") {
            this.postResult(body, (data) => this.handleSaveResponse(data))

        } else if (result.reason === "ended") {
            // 途中終了時は保存ボタンを表示してユーザーの判断に委ねる
            if (this.isSignedIn()) {
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
        const csrfToken = this.csrfToken()
        fetch("/typing/results", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken
            },
            body: JSON.stringify(body)
        })
        .then(res => {
            if (!res.ok) throw new Error("Failed to save typing result")
            return res.json()
        })
        .then(data => onSuccess(data))
        .catch(() => {
            this.showSaveFailure()
        })
    }

    articleContext() {
        return {
            articleText: sessionStorage.getItem("typing_text"),
            articleTitle: sessionStorage.getItem("article_title") || "",
            articleId: sessionStorage.getItem("article_id") || null
        }
    }

    isSignedIn() {
        return document.querySelector('meta[name="user-signed-in"]')?.content === "true"
    }

    csrfToken() {
        return document.querySelector('meta[name="csrf-token"]')?.content || ""
    }

    handleSaveResponse(data, { allowSkipped = true, hideSaveButton = false } = {}) {
        if (data.status === "saved") {
            this.saveSuccessTarget.classList.remove("hidden")
            if (hideSaveButton) this.saveButtonTarget.classList.add("hidden")
            if (data.achievements?.length > 0) this.showAchievements(data.achievements)
        } else if (allowSkipped && data.status === "skipped") {
            this.saveSkippedTarget.classList.remove("hidden")
        } else {
            this.showSaveFailure()
        }
    }

    showSaveFailure() {
        this.saveFailedTarget.classList.remove("hidden")
    }

    formatTime(seconds) {
        const m = Math.floor(seconds / 60).toString().padStart(2, "0")
        const s = (seconds % 60).toString().padStart(2, "0")
        return `${m}:${s}`
    }

    // 0 → 最終値へカウントアップ表示する（ease-out cubic, 約800ms）
    animateNumber(target, finalValue, options = {}) {
        const duration = options.duration ?? 800
        const suffix = options.suffix ?? ""
        const formatter = options.formatter ?? ((v) => `${Math.round(v)}${suffix}`)

        if (!Number.isFinite(finalValue) || finalValue === 0) {
            target.textContent = formatter(finalValue || 0)
            return
        }

        const startTime = performance.now()
        const tick = (now) => {
            const elapsed = now - startTime
            const progress = Math.min(elapsed / duration, 1)
            const eased = 1 - Math.pow(1 - progress, 3)
            const current = finalValue * eased
            target.textContent = progress === 1 ? formatter(finalValue) : formatter(current)
            if (progress < 1) requestAnimationFrame(tick)
        }
        requestAnimationFrame(tick)
    }

    // CPM × 正答率 から総合ランクを算出して表示する
    applyRank(result) {
        if (!this.hasRankLetterTarget) return
        const cpm = result.cpm || 0
        const accuracy = result.accuracy || 0

        // 有効CPM（速度×精度）でランクを決める
        const effective = cpm * (accuracy / 100)
        let letter = "--"
        if (cpm > 0) {
            if (effective >= 280) letter = "S"
            else if (effective >= 200) letter = "A"
            else if (effective >= 140) letter = "B"
            else if (effective >= 80) letter = "C"
            else letter = "D"
        }

        // ランクの登場アニメーション（カウントアップと同タイミングで弾む）
        const el = this.rankLetterTarget
        el.textContent = letter
        requestAnimationFrame(() => {
            el.classList.add("transition-all", "duration-500", "ease-out")
            el.classList.remove("opacity-0", "scale-50")
            el.classList.add("opacity-100", "scale-100")
        })
    }

    // ミスした文字位置をヒートマップとして本文上に可視化する
    renderHeatmap(text, missIndices) {
        if (!this.hasMissHeatmapTarget || !this.hasHeatmapBodyTarget) return
        if (!text || !missIndices || missIndices.length === 0) return

        const missCounts = {}
        missIndices.forEach((i) => { missCounts[i] = (missCounts[i] || 0) + 1 })

        const chars = [...text]
        const fragment = document.createDocumentFragment()
        chars.forEach((char, i) => {
            const count = missCounts[i] || 0
            const span = document.createElement("span")
            span.textContent = char
            if (count === 1) {
                span.className = "bg-red-500/25 rounded-sm"
            } else if (count === 2) {
                span.className = "bg-red-500/50 rounded-sm text-red-100"
            } else if (count >= 3) {
                span.className = "bg-red-500/75 rounded-sm text-white"
            }
            fragment.appendChild(span)
        })

        this.heatmapBodyTarget.innerHTML = ""
        this.heatmapBodyTarget.appendChild(fragment)
        this.missHeatmapTarget.classList.remove("hidden")
    }

    // 紙吹雪を打ち上げる（ブランドカラー寄り）
    fireConfetti() {
        const colors = ["#22c55e", "#16a34a", "#86efac", "#f9fafb", "#fde047"]
        confetti({
            particleCount: 90,
            spread: 75,
            startVelocity: 35,
            origin: { y: 0.35 },
            colors
        })
        // 少し遅らせて左右からの追い打ち
        setTimeout(() => {
            confetti({ particleCount: 40, angle: 60, spread: 55, origin: { x: 0, y: 0.6 }, colors })
            confetti({ particleCount: 40, angle: 120, spread: 55, origin: { x: 1, y: 0.6 }, colors })
        }, 200)
    }

    // 途中終了時に保存するかの選択で「保存する」を選んだ場合の処理
    saveManually() {
        const result = JSON.parse(sessionStorage.getItem("typing_result"))
        const { articleText, articleTitle, articleId } = this.articleContext()
        const body = this.buildResultBody(result, articleText, articleTitle, articleId)

        this.postResult(body, (data) => this.handleSaveResponse(data, {
            allowSkipped: false,
            hideSaveButton: true
        }))
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
        if (!this.isSignedIn()) return

        fetch("/typing/results/share_achievement", {
            method: "POST",
            headers: { "X-CSRF-Token": this.csrfToken() }
        }).catch(() => {})
    }

    showAchievements(achievements) {
        if (!this.hasAchievementBannersTarget) return

        const container = this.achievementBannersTarget
        achievements.forEach((a, i) => {
            const el = document.createElement("div")
            el.className = "flex justify-center opacity-0 scale-90 transition-all duration-300 ease-out"
            el.innerHTML = `
                <div class="inline-flex items-center gap-2 rounded-full bg-gray-800 border border-green-700 px-4 py-2 text-sm font-bold text-green-400">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.562.562 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                    </svg>
                    実績解除: <span data-achievement-name></span>
                </div>
            `
            el.querySelector("[data-achievement-name]").textContent = a.name
            container.appendChild(el)
            // ステージング（順番に弾むように登場）
            setTimeout(() => {
                el.classList.remove("opacity-0", "scale-90")
                el.classList.add("opacity-100", "scale-100")
            }, 80 + i * 160)
        })
        if (achievements.length > 0) {
            this.fireConfetti()
        }
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
