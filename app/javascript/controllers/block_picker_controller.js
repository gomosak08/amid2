import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin from "@fullcalendar/interaction"

// ─────────────────────────────────────────────────────────────────────────────
// block-picker controller
//
// Targets:
//   dayCalendar      – the div where the day-picker calendar renders
//   weekCalendar     – the div where the recurring-block calendar renders
//   startDate        – hidden input for single day / range start
//   endDate          – hidden input for range end (day picker)
//   startsAt         – hidden input for recurring block start time (HH:MM)
//   endsAt           – hidden input for recurring block end time (HH:MM)
//   daysOfWeek       – hidden input (JSON array) of day numbers for the recurrent block
//   dayDisplay       – text node showing currently selected days
//   timeDisplay      – text node showing currently selected time range
//   daySubmit        – submit button for day-block form (enabled once selection made)
//   timeSubmit       – submit button for time-block form (enabled once selection made)
// ─────────────────────────────────────────────────────────────────────────────

export default class extends Controller {
  static targets = [
    "dayCalendar", "weekCalendar",
    "startDate", "endDate",
    "startsAt", "endsAt", "daysOfWeek",
    "dayDisplay", "timeDisplay",
    "daySubmit", "timeSubmit"
  ]

  connect() {
    this._daySelection = null   // { start: Date, end: Date }
    this._timeSelection = null  // { start: Date, end: Date, days: number[] }
    this._dayEvents = []        // list of selected day-events in day calendar
    this._dayCal = null
    this._weekCal = null

    // Build day-picker calendar
    if (this.hasDayCalendarTarget) {
      this._buildDayCalendar()
    }

    // Build week-picker calendar
    if (this.hasWeekCalendarTarget) {
      this._buildWeekCalendar()
    }
  }

  disconnect() {
    this._dayCal?.destroy()
    this._weekCal?.destroy()
  }

  // ── DAY CALENDAR ──────────────────────────────────────────────────────────

  _buildDayCalendar() {
    const self = this

    this._dayCal = new Calendar(this.dayCalendarTarget, {
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      locale: "es",
      firstDay: 1,
      height: "auto",
      selectable: true,
      unselectAuto: false,

      headerToolbar: {
        left: "prev,next",
        center: "title",
        right: "today"
      },

      // Allow selecting multiple day ranges
      select(info) {
        // FullCalendar end is exclusive — subtract 1 day for display/storage
        const startDate = info.startStr                            // YYYY-MM-DD
        const endExclusive = info.end
        const endDate = new Date(endExclusive)
        endDate.setDate(endDate.getDate() - 1)
        const endStr = endDate.toISOString().slice(0, 10)         // YYYY-MM-DD

        self._daySelection = { start: startDate, end: endStr }

        // Update hidden inputs
        self.startDateTarget.value = startDate
        self.endDateTarget.value = endStr

        // Highlight + display
        self._dayCal.getEvents().forEach(e => e.remove())
        self._dayCal.addEvent({
          start: startDate,
          end: info.endStr,          // keep exclusive for FC display
          display: "background",
          color: "#ef4444",
          overlap: false
        })

        const sameDay = startDate === endStr
        const label = sameDay
          ? self._fmtDate(startDate)
          : `${self._fmtDate(startDate)} → ${self._fmtDate(endStr)}`

        if (self.hasDayDisplayTarget) self.dayDisplayTarget.textContent = label
        if (self.hasDaySubmitTarget)  self.daySubmitTarget.disabled = false
      },

      unselect() {
        self._daySelection = null
        self.startDateTarget.value = ""
        self.endDateTarget.value = ""
        self._dayCal.getEvents().forEach(e => e.remove())
        if (self.hasDayDisplayTarget) self.dayDisplayTarget.textContent = "Ningún día seleccionado"
        if (self.hasDaySubmitTarget)  self.daySubmitTarget.disabled = true
      }
    })

    this._dayCal.render()
    if (this.hasDaySubmitTarget) this.daySubmitTarget.disabled = true
  }

  // ── WEEK CALENDAR (recurrent block picker) ────────────────────────────────

  _buildWeekCalendar() {
    const self = this

    this._weekCal = new Calendar(this.weekCalendarTarget, {
      plugins: [timeGridPlugin, interactionPlugin],
      initialView: "timeGridWeek",
      locale: "es",
      firstDay: 1,
      height: "auto",
      selectable: true,
      unselectAuto: false,
      allDaySlot: false,
      nowIndicator: false,
      slotMinTime: "06:00:00",
      slotMaxTime: "22:00:00",
      slotDuration: "00:15:00",
      snapDuration: "00:15:00",

      headerToolbar: {
        left: "",
        center: "title",
        right: ""
      },

      // Add a permanent "last week" so the week displayed shows clear day names
      // (use a fixed reference date so days of the week are always visible)

      // When user drags a block on ANY column in the week view…
      select(info) {
        const startTime = self._timeStr(info.start)   // "HH:MM"
        const endTime   = self._timeStr(info.end)
        const dayNum    = info.start.getDay()          // 0=Sun…6=Sat

        // Collect all currently selected days + add this one
        // (allow building up multiple days of the same time block)
        let days = []
        try { days = JSON.parse(self.daysOfWeekTarget.value || "[]") } catch(_) {}

        if (!days.includes(dayNum)) days.push(dayNum)
        days.sort()

        self._timeSelection = { startTime, endTime, days }

        // Update hidden inputs
        self.startsAtTarget.value   = startTime
        self.endsAtTarget.value     = endTime
        self.daysOfWeekTarget.value = JSON.stringify(days)

        // Re-draw events: clear + add one event per selected day this week
        self._weekCal.getEvents().forEach(e => e.remove())
        self._drawWeekEvents(startTime, endTime, days)

        // Display label
        const dayNames = days.map(d => ["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"][d]).join(", ")
        const label = `${startTime} – ${endTime} | Días: ${dayNames}`
        if (self.hasTimeDisplayTarget) self.timeDisplayTarget.textContent = label
        if (self.hasTimeSubmitTarget)  self.timeSubmitTarget.disabled = false
      },

      unselect() {
        // Don't clear on unselect — let user accumulate selections
      }
    })

    this._weekCal.render()
    if (this.hasTimeSubmitTarget) this.timeSubmitTarget.disabled = true
  }

  // Draw background events for each selected day at the chosen time slot
  _drawWeekEvents(startTime, endTime, days) {
    if (!this._weekCal) return

    // Get the date of Monday of the current visible week
    const calDate = this._weekCal.view.currentStart  // Monday (firstDay:1)

    days.forEach(dayNum => {
      // Calculate offset: calDate is Monday (wday=1), dayNum is 0-6
      const offset = (dayNum === 0) ? 6 : dayNum - 1  // Mon=0 offset
      const d = new Date(calDate)
      d.setDate(d.getDate() + offset)

      const dateStr = d.toISOString().slice(0, 10)
      this._weekCal.addEvent({
        start: `${dateStr}T${startTime}:00`,
        end:   `${dateStr}T${endTime}:00`,
        display: "background",
        color: "#f97316",
        overlap: false
      })
    })
  }

  // Allow the user to clear the week selection and start over
  clearWeekSelection() {
    this._timeSelection = null
    this.startsAtTarget.value   = ""
    this.endsAtTarget.value     = ""
    this.daysOfWeekTarget.value = "[]"
    this._weekCal?.getEvents().forEach(e => e.remove())
    if (this.hasTimeDisplayTarget) this.timeDisplayTarget.textContent = "Ningún horario seleccionado"
    if (this.hasTimeSubmitTarget)  this.timeSubmitTarget.disabled = true
  }

  clearDaySelection() {
    this._dayCal?.unselect()
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  _timeStr(date) {
    const h = String(date.getHours()).padStart(2, "0")
    const m = String(date.getMinutes()).padStart(2, "0")
    return `${h}:${m}`
  }

  _fmtDate(str) {
    // str = YYYY-MM-DD
    const [y, mo, d] = str.split("-")
    const months = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"]
    return `${d} ${months[parseInt(mo,10)-1]} ${y}`
  }
}
