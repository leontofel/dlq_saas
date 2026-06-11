import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "submitButton", "tokenPanel", "tokenValue", "identity", "copyButton"]
  static values = {
    mode: String,
    redirectUrl: String,
    actionLabel: String
  }

  async submit(event) {
    event.preventDefault()

    this.setBusy(true)
    this.hideStatus()
    this.hideTokenPanel()

    try {
      const response = await fetch(this.element.action, {
        method: this.element.method.toUpperCase(),
        headers: {
          Accept: "application/json"
        },
        body: new FormData(this.element)
      })

      const payload = await response.json().catch(() => ({}))

      if (!response.ok) {
        this.showStatus(payload.error || "We could not process that request.", "error")
        return
      }

      if (this.modeValue === "login") {
        this.handleLoginSuccess(payload)
      } else {
        this.handleSignUpSuccess(payload)
      }
    } catch (error) {
      this.showStatus("Network error. Please try again.", "error")
    } finally {
      this.setBusy(false)
    }
  }

  async copyToken() {
    if (!this.hasTokenValueTarget) return

    try {
      await navigator.clipboard.writeText(this.tokenValueTarget.textContent.trim())

      if (this.hasCopyButtonTarget) {
        const original = this.copyButtonTarget.textContent
        this.copyButtonTarget.textContent = "Copied"
        window.setTimeout(() => {
          this.copyButtonTarget.textContent = original
        }, 1200)
      }
    } catch (_error) {
      this.showStatus("Could not copy the token automatically.", "error")
    }
  }

  handleLoginSuccess(payload) {
    if (payload.access_token) {
      window.localStorage.setItem("dlq_saas.access_token", payload.access_token)
    }

    if (payload.user) {
      window.localStorage.setItem("dlq_saas.user", JSON.stringify(payload.user))
    }

    if (this.hasIdentityTarget) {
      this.identityTarget.textContent = payload.user?.email || "Signed in"
    }

    if (this.hasTokenValueTarget) {
      this.tokenValueTarget.textContent = payload.access_token || ""
    }

    this.showStatus("Login successful. Your access token is ready below.", "success")
    this.showTokenPanel()
  }

  handleSignUpSuccess(_payload) {
    this.element.reset()
    this.showStatus("Account created. Redirecting you to login.", "success")

    if (this.redirectUrlValue) {
      window.setTimeout(() => {
        window.location.assign(this.redirectUrlValue)
      }, 900)
    }
  }

  setBusy(isBusy) {
    if (!this.hasSubmitButtonTarget) return

    this.submitButtonTarget.disabled = isBusy
    this.submitButtonTarget.textContent = isBusy ? "Working..." : this.actionLabelValue
  }

  showStatus(message, tone) {
    if (!this.hasStatusTarget) return

    this.statusTarget.hidden = false
    this.statusTarget.textContent = message
    this.statusTarget.dataset.tone = tone
  }

  hideStatus() {
    if (!this.hasStatusTarget) return

    this.statusTarget.hidden = true
    this.statusTarget.textContent = ""
    delete this.statusTarget.dataset.tone
  }

  showTokenPanel() {
    if (this.hasTokenPanelTarget) {
      this.tokenPanelTarget.hidden = false
    }
  }

  hideTokenPanel() {
    if (this.hasTokenPanelTarget) {
      this.tokenPanelTarget.hidden = true
    }
  }
}
