import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static targets = ["calendar", "popover", "popoverTitle", "popoverMeta", "popoverBody", "popoverFooter"]
  static values = { eventsUrl: String }

  connect() {
    this._hideTimer = null

    // Permite hover sobre el popover sin que desaparezca
    if (this.hasPopoverTarget) {
      this.popoverTarget.addEventListener("mouseenter", () => this.cancelHide())
      this.popoverTarget.addEventListener("mouseleave", () => this.scheduleHide())
    }

    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      initialView: "timeGridWeek",
      locale: "es",
      firstDay: 1,
      height: "auto",
      nowIndicator: true,
      expandRows: true,

      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay"
      },

      events: (info, success, failure) => {
        const url = new URL(this.eventsUrlValue, window.location.origin)
        url.searchParams.set("start", info.startStr)
        url.searchParams.set("end", info.endStr)

        fetch(url)
          .then(r => r.json())
          .then((events) => {
            const filtered = (events || []).filter((ev) => {
              const kind = ev?.extendedProps?.kind
              return ["cita", "bloqueo_dia", "bloqueo_horas"].includes(kind)
            })
            success(filtered)
          })
          .catch(failure)
      },

      eventDidMount: (info) => {
        info.el.style.cursor = "pointer"

        info.el.addEventListener("mouseenter", (e) => {
          this.cancelHide()
          this.showPopoverForEvent(info.event, e.clientX, e.clientY)
        })

        info.el.addEventListener("mouseleave", () => this.scheduleHide())
      },

      eventClick: (info) => {
        info.jsEvent.preventDefault()
        this.cancelHide()
        this.showPopoverForEvent(info.event, info.jsEvent.clientX, info.jsEvent.clientY)
      }
    })

    this.calendar.render()
  }

  disconnect() {
    if (this.calendar) this.calendar.destroy()
  }

  hidePopover() {
    if (!this.hasPopoverTarget) return
    this.popoverTarget.classList.add("hidden")
  }

  scheduleHide() {
    this.cancelHide()
    this._hideTimer = setTimeout(() => this.hidePopover(), 180)
  }

  cancelHide() {
    if (this._hideTimer) clearTimeout(this._hideTimer)
    this._hideTimer = null
  }

  showPopoverForEvent(event, x, y) {
    if (!this.hasPopoverTarget) return

    const p = event.extendedProps || {}
    const kind = p.kind

    // Title
    this.popoverTitleTarget.textContent =
      kind === "cita" ? (event.title || "Cita") :
      kind === "bloqueo_dia" ? "Bloqueo de día completo" :
      kind === "bloqueo_horas" ? (p.reason || "Bloqueo por horas") :
      (event.title || "Evento")

    // Meta (fecha + rango)
    const start = event.start
    const end = event.end
    const day = start ? this.formatDate(start) : ""
    const range = (start && end) ? `${this.formatTime(start)}–${this.formatTime(end)}` : ""
    this.popoverMetaTarget.textContent = [day, range].filter(Boolean).join(" · ")

    // Body
    if (kind === "cita") {
      this.popoverBodyTarget.innerHTML = `
        <div class="space-y-1">
          ${p.patient_name ? `<div><span class="text-xs text-gray-500">Paciente:</span> <span class="ml-1">${this.escapeHtml(p.patient_name)}</span></div>` : ""}
          ${p.package_name ? `<div><span class="text-xs text-gray-500">Paquete:</span> <span class="ml-1">${this.escapeHtml(p.package_name)}</span></div>` : ""}
          <div><span class="text-xs text-gray-500">Agendada por:</span> <span class="ml-1">${this.escapeHtml(p.scheduled_by_label || p.scheduled_by || "N/A")}</span></div>
          ${p.status ? `<div><span class="text-xs text-gray-500">Estado:</span> <span class="ml-1">${this.escapeHtml(p.status)}</span></div>` : ""}
        </div>
      `
      this.popoverFooterTarget.textContent = `ID: ${p.record_id ?? ""}`

    } else if (kind === "bloqueo_horas") {
      this.popoverBodyTarget.innerHTML = `
        <div class="space-y-1">
          <div><span class="text-xs text-gray-500">Motivo:</span> <span class="ml-1">${this.escapeHtml(p.reason || "—")}</span></div>
          <div><span class="text-xs text-gray-500">Horario:</span> <span class="ml-1">${this.escapeHtml(p.starts_at || "")}–${this.escapeHtml(p.ends_at || "")}</span></div>
        </div>
      `
      this.popoverFooterTarget.textContent = `ID: ${p.record_id ?? ""}`

    } else if (kind === "bloqueo_dia") {
      this.popoverBodyTarget.innerHTML = `
        <div>
          ${p.reason ? this.escapeHtml(p.reason) : '<span class="text-gray-500">Sin motivo.</span>'}
        </div>
      `
      this.popoverFooterTarget.textContent = `ID: ${p.record_id ?? ""}`

    } else {
      this.popoverBodyTarget.textContent = ""
      this.popoverFooterTarget.textContent = ""
    }

    this.popoverTarget.classList.remove("hidden")
    this.positionPopover(x, y)
  }

  positionPopover(mouseX, mouseY) {
    const pop = this.popoverTarget
    const padding = 12
    const offset = 14

    pop.style.left = "0px"
    pop.style.top = "0px"
    const rect = pop.getBoundingClientRect()

    let px = mouseX + offset
    let py = mouseY + offset

    const vw = window.innerWidth
    const vh = window.innerHeight

    if (px + rect.width + padding > vw) px = vw - rect.width - padding
    if (py + rect.height + padding > vh) py = vh - rect.height - padding
    if (px < padding) px = padding
    if (py < padding) py = padding

    pop.style.left = `${Math.round(px)}px`
    pop.style.top = `${Math.round(py)}px`
  }

  formatDate(d) {
    return new Intl.DateTimeFormat("es-MX", {
      weekday: "short", year: "numeric", month: "short", day: "2-digit"
    }).format(d)
  }

  formatTime(d) {
    return new Intl.DateTimeFormat("es-MX", { hour: "2-digit", minute: "2-digit" }).format(d)
  }

  escapeHtml(str) {
    return String(str)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;")
  }
}