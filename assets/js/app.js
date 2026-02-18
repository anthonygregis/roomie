// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket, Presence} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/roomie"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.RoomChannel = {
  mounted() {
    const roomCode = this.el.dataset.roomCode
    const name = this.el.dataset.name
    const clientId = localStorage.getItem("roomie_client_id") || 
    (() => {
      const v = crypto.randomUUID()
      localStorage.setItem("roomie_client_id", v)
      return v
    })()

    if (!name) return

    // Connecto to our custom channel socket endpoint: /socket
    this.socket = new Socket("/socket", {params: {}})
    this.socket.connect()

    // Join the topic: room:<code>
    this.channel = this.socket.channel(`room:${roomCode}`, {name, client_id: clientId})

    // Presence is a client helper that merges a presence_state + presence_diff
    this.presence = new Presence(this.channel)

    const rosterEl = document.getElementById("roster")
    const messagesEl = document.getElementById("messages")
    const formEl = document.getElementById("msg-form")
    const inputEl = document.getElementById("msg-input")

    const statusFromLastActive = (iso) => {
      if (!iso) return "away"

      const ms = Date.now() - new Date(iso).getTime()
      return ms < 60_000 ? "active" : "away"
    }

    const renderRoster = () => {
      rosterEl.innerHTML = ""

      // list() returns an array of entries: [{key, metas}, ...]
      const entries = this.presence.list((key, {metas}) => ({key, metas}))
      
      entries
        .sort((a, b) => a.key.localeCompare(b.key))
        .forEach(({key, metas}) => {
          const meta = metas?.[0] || {}
          const displayName = meta.name || key
          const status = statusFromLastActive(meta.last_active_at || meta.joined_at)

          const li = document.createElement("li")
          li.textContent = `${displayName} · ${status}`
          rosterEl.appendChild(li)
        })
    }

    const appendMessage = (msg) => {
      const div = document.createElement("div")
      
      div.innerHTML = `<span class="text-zinc-500">${msg.at}</span> <b>${msg.name}</b>: ${msg.body}`
      messagesEl.appendChild(div)
      messagesEl.scrollTop = messagesEl.scrollHeight
    }

    // Presence sync triggers whenever state changes (join/leave)
    this.presence.onSync(renderRoster)

    // Server pushes the most recent messages after join
    this.channel.on("messages:recent", (payload) => {
      messagesEl.innerHTML = ""
      payload.messages.forEach(appendMessage)
    })

    // Server broadcasts each new message
    this.channel.on("message:new", appendMessage)

    // Start a timer to update presence status every 30 seconds
    this.rosterTimer = setInterval(() => {
      this.presence.update()
    }, 10_000)

    // Join the channel
    this.channel.join()
      .receive("ok", () => console.log("Joined room", roomCode))
      .receive("error", (resp) => console.error("Failed to join room", resp))

    // Send message from input
    formEl.addEventListener("submit", (e) => {
      e.preventDefault()

      const body = inputEl.value.trim()
      if (!body) return

      this.channel.push("message:new", {body})
      inputEl.value = ""
    })

    window.addEventListener("beforeunload", () => {
      try { this.channel?.leave() } catch {}
      try { this.socket?.disconnect() } catch {}
    })
  },

  destroyed() {
    if (this.rosterTimer) clearInterval(this.rosterTimer)
    if (this.channel) this.channel.leave()
    if (this.socket) this.socket.disconnect()
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...Hooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

