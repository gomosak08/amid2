import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static targets = [
    "calendar", "popover", "popoverTitle", "popoverMeta", "popoverBody", "popoverFooter",
    "selectedDate", "daySummary", "dayEmpty", "dayCount",
    "blockModal", "blockStartDate", "blockEndDate", "blockStartTime", "blockEndTime", "blockDisplay"
  ]
  static values = { eventsUrl: String }

  connect() {
    this._hideTimer = null
    this._events = []
    this._selectedDate = this.toDateKey(new Date())

    // Permite hover sobre el popover sin que desaparezca
    if (this.hasPopoverTarget) {
      this.popoverTarget.addEventListener("mouseenter", () => this.cancelHide())
      this.popoverTarget.addEventListener("mouseleave", () => this.scheduleHide())
    }

    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      locale: "es",
      firstDay: 1,
      height: "auto",
      nowIndicator: true,
      expandRows: true,
      allDayText: "Todo el día",
      noEventsText: "No hay eventos para mostrar",
      moreLinkText: "más",
      dayMaxEvents: 4,
      eventDisplay: "block",
      slotMinTime: "07:00:00",
      slotMaxTime: "21:00:00",
      slotDuration: "00:30:00",
      selectable: true,
      unselectAuto: false,
      eventTimeFormat: {
        hour: "2-digit",
        minute: "2-digit",
        meridiem: false
      },

      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay"
      },
      buttonText: {
        today: "Hoy",
        month: "Mes",
        week: "Semana",
        day: "Día"
      },
      navLinks: true,
      navLinkDayClick: "timeGridDay",
      dateClick: (info) => {
        this.openDay(info.date)
      },
      select: (info) => {
        this.showBlockModal(info)
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
            this._events = filtered
            this.renderDaySummary()
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
        this._selectedDate = this.toDateKey(info.event.start)
        this.renderDaySummary()
        this.showPopoverForEvent(info.event, info.jsEvent.clientX, info.jsEvent.clientY)
      }
    })

    this.calendar.render()
    this.renderDaySummary()
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

  openDay(date) {
    this._selectedDate = this.toDateKey(date)
    this.calendar.changeView("timeGridDay", date)
    this.renderDaySummary()
  }

  renderDaySummary() {
    if (!this.hasSelectedDateTarget || !this.hasDaySummaryTarget) return

    const selectedDate = this._selectedDate || this.toDateKey(new Date())
    this.selectedDateTarget.textContent = this.formatDateKey(selectedDate)

    const events = this.eventsForDate(selectedDate)
    if (this.hasDayCountTarget) {
      const citaCount = events.filter((event) => event?.extendedProps?.kind === "cita").length
      const bloqueosCount = events.length - citaCount
      this.dayCountTarget.textContent = `${citaCount} cita${citaCount === 1 ? "" : "s"} · ${bloqueosCount} bloqueo${bloqueosCount === 1 ? "" : "s"}`
    }

    this.daySummaryTarget.innerHTML = events.map((event) => this.daySummaryItem(event)).join("")
    if (this.hasDayEmptyTarget) {
      this.dayEmptyTarget.classList.toggle("hidden", events.length > 0)
    }
  }

  eventsForDate(dateKey) {
    return (this._events || [])
      .filter((event) => this.eventTouchesDate(event, dateKey))
      .sort((a, b) => new Date(a.start) - new Date(b.start))
  }

  eventTouchesDate(event, dateKey) {
    const start = new Date(event.start)
    const end = event.end ? new Date(event.end) : start
    const dayStart = this.dateKeyToLocalDate(dateKey)
    const dayEnd = new Date(dayStart)
    dayEnd.setDate(dayEnd.getDate() + 1)

    return start < dayEnd && end > dayStart
  }

  daySummaryItem(event) {
    const p = event.extendedProps || {}
    const kind = p.kind
    const colorClass =
      kind === "cita" ? "border-blue-200 bg-blue-50 text-blue-700" :
      kind === "bloqueo_dia" ? "border-red-200 bg-red-50 text-red-700" :
      "border-orange-200 bg-orange-50 text-orange-700"
    const label =
      kind === "cita" ? "Cita" :
      kind === "bloqueo_dia" ? "Bloqueo día" :
      "Bloqueo horas"
    const title =
      kind === "cita" ? (p.patient_name || event.title || "Cita") :
      kind === "bloqueo_dia" ? (p.reason || "Día bloqueado") :
      (p.reason || "Horario bloqueado")
    const start = new Date(event.start)
    const end = event.end ? new Date(event.end) : null
    const time =
      event.allDay ? "Todo el día" :
      end ? `${this.formatTime(start)} - ${this.formatTime(end)}` :
      this.formatTime(start)
    const detail =
      kind === "cita" ? [p.package_name, this.translateStatus(p.status)].filter(Boolean).join(" · ") :
      kind === "bloqueo_horas" ? `${p.starts_at || ""} - ${p.ends_at || ""}` :
      "No disponible"

    return `
      <button type="button"
              class="w-full rounded-xl border border-gray-200 bg-white px-3 py-3 text-left shadow-sm transition hover:border-blue-200 hover:bg-blue-50/40"
              data-action="click->doctor-calendar#focusSummaryEvent"
              data-event-id="${this.escapeHtml(event.id)}">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <div class="truncate text-sm font-semibold text-gray-900">${this.escapeHtml(title)}</div>
            <div class="mt-1 text-xs text-gray-500">${this.escapeHtml(time)}</div>
            ${detail ? `<div class="mt-1 truncate text-xs text-gray-600">${this.escapeHtml(detail)}</div>` : ""}
          </div>
          <span class="shrink-0 rounded-full border px-2 py-0.5 text-[11px] font-semibold ${colorClass}">
            ${label}
          </span>
        </div>
      </button>
    `
  }

  focusSummaryEvent(event) {
    const id = event.currentTarget.dataset.eventId
    const calendarEvent = this.calendar?.getEventById(id)
    if (!calendarEvent) return

    this.calendar.changeView("timeGridDay", calendarEvent.start)
    this._selectedDate = this.toDateKey(calendarEvent.start)
    this.renderDaySummary()
    calendarEvent.setProp("classNames", ["doctor-calendar-event-pulse"])
    setTimeout(() => calendarEvent.setProp("classNames", []), 900)
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
          ${p.status ? `<div><span class="text-xs text-gray-500">Estado:</span> <span class="ml-1">${this.escapeHtml(this.translateStatus(p.status))}</span></div>` : ""}
        </div>
      `
      this.popoverFooterTarget.textContent = ""

    } else if (kind === "bloqueo_horas") {
      this.popoverBodyTarget.innerHTML = `
        <div class="space-y-1">
          <div><span class="text-xs text-gray-500">Motivo:</span> <span class="ml-1">${this.escapeHtml(p.reason || "—")}</span></div>
          <div><span class="text-xs text-gray-500">Horario:</span> <span class="ml-1">${this.escapeHtml(p.starts_at || "")}–${this.escapeHtml(p.ends_at || "")}</span></div>
        </div>
      `
      this.popoverFooterTarget.textContent = ""

    } else if (kind === "bloqueo_dia") {
      this.popoverBodyTarget.innerHTML = `
        <div>
          ${p.reason ? this.escapeHtml(p.reason) : '<span class="text-gray-500">Sin motivo.</span>'}
        </div>
      `
      this.popoverFooterTarget.textContent = ""

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
      weekday: "short", year: "numeric", month: "short", day: "2-digit",
      timeZone: "America/Mexico_City"
    }).format(d)
  }

  formatDateKey(dateKey) {
    return this.formatDate(this.dateKeyToLocalDate(dateKey))
  }

  formatTime(d) {
    return new Intl.DateTimeFormat("es-MX", {
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "America/Mexico_City"
    }).format(d)
  }

  translateStatus(status) {
    const map = {
      0:                  "Agendada",
      1:                  "Cancelada por admin",
      2:                  "Cancelada por cliente",
      3:                  "Completada",
      scheduled:          "Agendada",
      confirmed:          "Confirmada",
      completed:          "Completada",
      attended:           "Atendida",
      pending:            "Pendiente",
      canceled:           "Cancelada",
      canceled_by_admin:  "Cancelada por admin",
      canceled_by_client: "Cancelada por cliente",
      no_show:            "No se presentó",
      rescheduled:        "Reprogramada",
      in_progress:        "En progreso"
    }
    const key = String(status ?? "")
    return map[key] || map[key.toLowerCase()] || status
  }

  showBlockModal(info) {
    if (!this.hasBlockModalTarget) return

    const allDay = info.allDay
    let sDate = new Date(info.start)
    let eDate = new Date(info.end)

    if (allDay) {
      eDate.setDate(eDate.getDate() - 1)
    }

    const startDateStr = info.startStr.split("T")[0]
    const endDateStr = eDate.toISOString().split("T")[0]

    let startTimeStr = ""
    let endTimeStr = ""
    let label = ""

    if (allDay) {
      const sameDay = startDateStr === endDateStr
      label = sameDay
        ? `${this.formatDateKey(startDateStr)} (Todo el día)`
        : `${this.formatDateKey(startDateStr)} → ${this.formatDateKey(endDateStr)} (Todo el día)`
    } else {
      startTimeStr = this.formatTime24(info.start)
      endTimeStr = this.formatTime24(info.end)
      const sameDay = startDateStr === endDateStr

      if (sameDay) {
        label = `${this.formatDateKey(startDateStr)} de ${startTimeStr} a ${endTimeStr}`
      } else {
        label = `${this.formatDateKey(startDateStr)} ${startTimeStr} → ${this.formatDateKey(endDateStr)} ${endTimeStr}`
      }
    }

    this.blockStartDateTarget.value = startDateStr
    this.blockEndDateTarget.value = endDateStr
    this.blockStartTimeTarget.value = startTimeStr
    this.blockEndTimeTarget.value = endTimeStr
    this.blockDisplayTarget.textContent = label

    this.blockModalTarget.classList.remove("hidden")
  }

  hideBlockModal() {
    if (!this.hasBlockModalTarget) return
    this.blockModalTarget.classList.add("hidden")
    if (this.calendar) this.calendar.unselect()
  }

  formatTime24(d) {
    const hours = String(d.getHours()).padStart(2, '0')
    const mins = String(d.getMinutes()).padStart(2, '0')
    return `${hours}:${mins}`
  }

  toDateKey(date) {
    const d = new Date(date)
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, "0")
    const day = String(d.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  dateKeyToLocalDate(dateKey) {
    const [year, month, day] = dateKey.split("-").map(Number)
    return new Date(year, month - 1, day)
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
