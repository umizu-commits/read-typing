import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js/auto"

export default class extends Controller {
  static values = { data: Array }

  connect() {
    const data = this.dataValue
    const labels = data.map(d => d.label)
    const cpmPoints = data.map(d => d.cpm)
    const accuracyPoints = data.map(d => d.accuracy)

    // 自己ベスト点はダイヤモンド型 + 淡色ハロで強調
    const cpmPointStyles = data.map(d => d.is_best ? "rectRot" : "circle")
    const cpmPointRadius = data.map(d => d.is_best ? 6 : 3)
    const cpmPointBgColors = data.map(() => "#22c55e")
    const cpmPointBorderColors = data.map(d => d.is_best ? "#bbf7d0" : "#22c55e")
    const cpmPointBorderWidth = data.map(d => d.is_best ? 2 : 1)

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            label: "CPM",
            data: cpmPoints,
            borderColor: "#22c55e",
            backgroundColor: "transparent",
            tension: 0,
            pointRadius: cpmPointRadius,
            pointHoverRadius: cpmPointRadius.map(r => r + 2),
            pointBackgroundColor: cpmPointBgColors,
            pointBorderColor: cpmPointBorderColors,
            pointBorderWidth: cpmPointBorderWidth,
            pointStyle: cpmPointStyles,
            yAxisID: "y"
          },
          {
            label: "正答率",
            data: accuracyPoints,
            borderColor: "#22d3ee",
            backgroundColor: "transparent",
            borderDash: [4, 4],
            borderWidth: 1.5,
            tension: 0,
            pointRadius: 2,
            pointHoverRadius: 4,
            pointBackgroundColor: "#22d3ee",
            yAxisID: "y1"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        devicePixelRatio: 2,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: {
            display: true,
            position: "top",
            align: "end",
            labels: { color: "#9ca3af", boxWidth: 12, boxHeight: 12, padding: 12, font: { size: 11 } }
          },
          tooltip: {
            backgroundColor: "#1f2937",
            titleColor: "#f3f4f6",
            bodyColor: "#d1d5db",
            borderColor: "#374151",
            borderWidth: 1,
            padding: 10,
            displayColors: true,
            callbacks: {
              title: (items) => {
                if (!items.length) return ""
                return data[items[0].dataIndex].full_label
              },
              afterTitle: (items) => {
                if (!items.length) return ""
                const title = data[items[0].dataIndex].title
                if (!title) return ""
                return title.length > 40 ? title.slice(0, 39) + "…" : title
              },
              label: (item) => {
                const idx = item.dataIndex
                if (item.datasetIndex === 0) {
                  const best = data[idx].is_best ? "  (自己ベスト)" : ""
                  return `CPM: ${item.parsed.y}${best}`
                }
                return `正答率: ${item.parsed.y}%`
              }
            }
          }
        },
        scales: {
          x: {
            grid: { color: "rgba(255,255,255,0.07)" },
            ticks: {
              color: "#9ca3af",
              maxTicksLimit: 8,
              maxRotation: 30,
              minRotation: 30,
              font: { size: 12 }
            }
          },
          y: {
            position: "left",
            beginAtZero: true,
            grid: { color: "rgba(255,255,255,0.07)" },
            ticks: { color: "#22c55e", font: { size: 12 } }
          },
          y1: {
            position: "right",
            min: 0,
            max: 100,
            grid: { display: false },
            ticks: {
              color: "#22d3ee",
              font: { size: 12 },
              callback: (v) => `${v}%`
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
