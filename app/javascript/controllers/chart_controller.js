import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js/auto"

export default class extends Controller {
  static values = { data: Array }

  connect() {
    const labels = this.dataValue.map(([label]) => label)
    const points = this.dataValue.map(([, value]) => value)

    this.chart = new Chart(this.element, {
      type: "line",
      data: {
        labels,
        datasets: [{
          data: points,
          borderColor: "#22c55e",
          backgroundColor: "transparent",
          tension: 0,
          pointRadius: 3,
          pointBackgroundColor: "#22c55e"
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        devicePixelRatio: 2,
        plugins: { legend: { display: false } },
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
            grid: { color: "rgba(255,255,255,0.07)" },
            ticks: { color: "#9ca3af", font: { size: 12 } }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
