// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// data-turbo-confirm のネイティブ confirm を自作モーダルに置き換える。
// confirm_modal_controller がカスタムイベントを受けてモーダルを表示する。
window.Turbo.setConfirmMethod((message) => {
  return new Promise((resolve) => {
    document.dispatchEvent(new CustomEvent("confirm:open", {
      detail: { message, resolve }
    }))
  })
})
