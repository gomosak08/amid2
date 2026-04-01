path = '/home/gomosak/platzi/platzi/amid2/app/views/admin/doctors/edit.html.erb'
lines = File.readlines(path)

# Extract sections
header = lines[0..29].join
resumen = lines[30..74].join
formulario = lines[75..90].join
cuerpo = lines[91..478].join
calendario = lines[479..540].join
scripts = lines[541..-1].join

str = []

header.sub!(
  '        Administra la información del doctor, configura disponibilidad, crea bloqueos y revisa sus citas en calendario.',
  '        Administra la información de <%= @doctor.name %>, configura disponibilidad, crea bloqueos y revisa sus citas en calendario.'
)

str << header

str << <<-HTML
  <- TABS NAV -->
  <div class="mt-8 border-b border-gray-200">
    <nav class="-mb-px flex space-x-8 overflow-x-auto" aria-label="Tabs" id="doctor-tabs-nav">
      <button type="button" onclick="openTab('tab-perfil', this)" class="tab-btn active-tab whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition" aria-current="page">
        Perfil y Horarios
      </button>

      <button type="button" onclick="openTab('tab-calendario', this)" class="tab-btn inactive-tab whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition">
        Calendario
      </button>

      <button type="button" onclick="openTab('tab-bloqueos', this)" class="tab-btn inactive-tab whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition">
        Excepciones y Bloqueos
      </button>
    </nav>
  </div>

  <style>
    .active-tab { border-color: #2563eb; color: #1e40af; }
    .inactive-tab { border-color: transparent; color: #6b7280; }
    .inactive-tab:hover { border-color: #d1d5db; color: #374151; }
    .tab-content { display: none; }
    .tab-content.active { display: block; animation: fadeIn 0.3s ease-in-out; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: translateY(0); } }
  </style>

  <script>
    function openTab(tabId, btn) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
      document.getElementById(tabId).classList.add('active');

      document.querySelectorAll('.tab-btn').forEach(b => {
        b.classList.remove('active-tab');
        b.classList.add('inactive-tab');
      });
      btn.classList.remove('inactive-tab');
      btn.classList.add('active-tab');
      
      if(tabId === 'tab-calendario') {
        window.dispatchEvent(new Event('resize'));
      }
    }
  </script>

HTML

str << "  <!-- TAB 1: PERFIL -->\n  <div id=\"tab-perfil\" class=\"tab-content active mt-8\">\n"
str << formulario
str << "  </div>\n\n"

str << "  <!-- TAB 2: CALENDARIO -->\n  <div id=\"tab-calendario\" class=\"tab-content mt-4\">\n"
str << calendario
str << "  </div>\n\n"

str << "  <!-- TAB 3: BLOQUEOS -->\n  <div id=\"tab-bloqueos\" class=\"tab-content mt-8\">\n"
str << resumen
str << cuerpo
str << "  </div>\n\n"

str << "</div>\n"
str << scripts

File.write(path, str.join)

