import {  Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show () {
    document.getElementById("ai-loading").classList.add("is-active")
  }
}
