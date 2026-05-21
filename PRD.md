# 📋 Product Requirements Document (PRD)
# Realtime ERP Notification System

**Versi:** 1.0.0  
**Tanggal:** 2026-05-20  
**Tech Stack:** Elixir · Phoenix Framework · PostgreSQL  
**Status:** Draft

---

## 1. Latar Belakang & Problem Statement

Sistem ERP modern sering gagal menyampaikan informasi kritis secara real-time kepada pengguna yang relevan. Akibatnya:

- Keterlambatan pengambilan keputusan bisnis
- Bottleneck pada proses approval dan workflow
- Kehilangan momen kritis (stok habis, invoice jatuh tempo)
- Kurangnya visibilitas lintas departemen

**Realtime ERP Notification System** hadir sebagai layanan terpusat yang menangkap event dari modul-modul ERP dan mendistribusikan notifikasi secara real-time ke pengguna yang tepat, melalui channel yang tepat, pada waktu yang tepat.

---

## 2. Tujuan Produk

| Tujuan | Metrik Keberhasilan |
|--------|-------------------|
| Notifikasi terkirim < 500ms dari event | Latency P99 < 500ms |
| Zero missed critical notifications | 99.99% delivery rate |
| Support 10.000+ concurrent connections | Load test: 10K WebSocket |
| Multi-channel delivery | 3 channel aktif di v1.0 |
| Audit trail lengkap | 100% events terlacak |

---

## 3. Target Pengguna

| Role | Kebutuhan Utama |
|------|----------------|
| **Manager / Approver** | Notifikasi approval request, budget overage |
| **Staff Gudang** | Alert stok kritis, purchase order masuk |
| **Finance Team** | Invoice jatuh tempo, pembayaran diterima |
| **Sales Team** | Order baru, konfirmasi pengiriman |
| **IT Admin** | System health alerts, error monitoring |
| **C-Level** | Ringkasan harian, KPI anomaly alerts |

---

## 4. Fitur Utama

### 4.1 Notification Engine (Core)
- **Event Ingestion**: Menerima event dari modul ERP via REST API atau internal PubSub
- **Rule Engine**: Menentukan siapa yang harus dinotifikasi berdasarkan rule/template
- **Priority System**: Level `critical`, `high`, `medium`, `low`
- **Deduplication**: Mencegah notifikasi duplikat dalam window waktu tertentu
- **Batching**: Mengelompokkan notifikasi frekuensi tinggi agar tidak spam

### 4.2 Realtime Delivery (Phoenix Channels)
- **WebSocket Channel**: Push notifikasi via `Phoenix.Channel`
- **User Channel**: Channel personal `notifications:user:{id}`
- **Role Channel**: Channel per role `notifications:role:{role_name}`
- **Presence Tracking**: Track user online via `Phoenix.Presence`

### 4.3 Multi-Channel Delivery

| Channel | Implementasi | Use Case |
|---------|-------------|----------|
| In-App (WebSocket) | Phoenix Channels | Notifikasi real-time di UI |
| Email | Swoosh + SMTP/SES | Notifikasi penting & digest |
| Webhook | HTTPoison | Integrasi sistem eksternal |
| SMS *(v2.0)* | Twilio / local gateway | Alert critical only |

### 4.4 Notification Management (Phoenix LiveView)
- **Inbox View**: List semua notifikasi dengan filter & search
- **Read/Unread State**: Tandai baca, tandai semua baca
- **Badge Counter**: Unread count realtime di navbar
- **Preferences**: User atur channel & frekuensi per tipe notifikasi

### 4.5 Admin Panel (Phoenix LiveView)
- **Event Log**: Semua event masuk beserta status delivery
- **Template Manager**: CRUD notification templates
- **Rule Manager**: Konfigurasi routing rules
- **Analytics Dashboard**: Delivery stats, engagement rate, channel performance

---

## 5. Arsitektur Sistem

```
┌──────────────────────────────────────────────────────┐
│              ERP Modules (Event Sources)              │
│  [Inventory] [Finance] [HR] [Sales] [Purchase]       │
└──────────────────────┬───────────────────────────────┘
                       │ REST API / Internal PubSub
                       ▼
┌──────────────────────────────────────────────────────┐
│         Realtime ERP Notification System             │
│                                                      │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │  Event     │  │ Rule Engine │  │ Notification │  │
│  │  Ingestion │─▶│ & Router   │─▶│ Dispatcher   │  │
│  │  (API)     │  │ (GenServer) │  │ (Supervisor) │  │
│  └────────────┘  └─────────────┘  └──────┬───────┘  │
│                                          │           │
│  ┌───────────────────────────────────────▼─────────┐ │
│  │              Delivery Workers                   │ │
│  │  [WebSocket Worker] [Email] [Webhook]           │ │
│  └─────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │  Phoenix   │  │ PostgreSQL  │  │ Phoenix.     │  │
│  │  LiveView  │  │ (Ecto)      │  │ PubSub       │  │
│  └────────────┘  └─────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────┘
              │             │             │
         [Browser]       [Email]     [Webhook]
         WebSocket         SMTP       HTTP POST
```

---

## 6. Data Model & Skema Database

### 6.1 `notification_events`
```sql
CREATE TABLE notification_events (
  id           BIGSERIAL    PRIMARY KEY,
  event_type   VARCHAR(100) NOT NULL,
  source       VARCHAR(100) NOT NULL,
  payload      JSONB        NOT NULL,
  priority     VARCHAR(20)  NOT NULL DEFAULT 'medium',
  processed    BOOLEAN      NOT NULL DEFAULT false,
  processed_at TIMESTAMPTZ,
  inserted_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_events_type      ON notification_events(event_type);
CREATE INDEX idx_events_processed ON notification_events(processed, inserted_at);
```

### 6.2 `notifications`
```sql
CREATE TABLE notifications (
  id          BIGSERIAL    PRIMARY KEY,
  user_id     BIGINT       NOT NULL REFERENCES users(id),
  event_id    BIGINT       REFERENCES notification_events(id),
  title       VARCHAR(255) NOT NULL,
  body        TEXT         NOT NULL,
  type        VARCHAR(100) NOT NULL,
  priority    VARCHAR(20)  NOT NULL DEFAULT 'medium',
  read        BOOLEAN      NOT NULL DEFAULT false,
  read_at     TIMESTAMPTZ,
  action_url  VARCHAR(500),
  metadata    JSONB,
  inserted_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notif_user_unread ON notifications(user_id, read, inserted_at DESC);
```

### 6.3 `notification_deliveries`
```sql
CREATE TABLE notification_deliveries (
  id                BIGSERIAL   PRIMARY KEY,
  notification_id   BIGINT      NOT NULL REFERENCES notifications(id),
  channel           VARCHAR(50) NOT NULL,
  status            VARCHAR(20) NOT NULL DEFAULT 'pending',
  attempt_count     INTEGER     NOT NULL DEFAULT 0,
  last_attempted_at TIMESTAMPTZ,
  delivered_at      TIMESTAMPTZ,
  error_message     TEXT,
  inserted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_delivery_status ON notification_deliveries(status, channel);
```

### 6.4 `notification_templates`
```sql
CREATE TABLE notification_templates (
  id         BIGSERIAL    PRIMARY KEY,
  name       VARCHAR(100) NOT NULL UNIQUE,
  event_type VARCHAR(100) NOT NULL,
  title_tmpl VARCHAR(255) NOT NULL,
  body_tmpl  TEXT         NOT NULL,
  channels   VARCHAR[]    NOT NULL DEFAULT '{websocket}',
  priority   VARCHAR(20)  NOT NULL DEFAULT 'medium',
  active     BOOLEAN      NOT NULL DEFAULT true,
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 6.5 `user_notification_preferences`
```sql
CREATE TABLE user_notification_preferences (
  id                BIGSERIAL    PRIMARY KEY,
  user_id           BIGINT       NOT NULL REFERENCES users(id),
  event_type        VARCHAR(100) NOT NULL,
  channel           VARCHAR(50)  NOT NULL,
  enabled           BOOLEAN      NOT NULL DEFAULT true,
  quiet_hours_start TIME,
  quiet_hours_end   TIME,
  digest_mode       BOOLEAN      NOT NULL DEFAULT false,
  UNIQUE(user_id, event_type, channel)
);
```

---

## 7. Struktur Proyek Elixir

```
lib/
├── erp_notification/
│   ├── events/
│   │   ├── event.ex               # Schema: notification_events
│   │   └── events.ex              # Context module
│   ├── notifications/
│   │   ├── notification.ex        # Schema: notifications
│   │   ├── delivery.ex            # Schema: notification_deliveries
│   │   ├── template.ex            # Schema: notification_templates
│   │   ├── preference.ex          # Schema: user_notification_preferences
│   │   └── notifications.ex       # Context module
│   ├── rules/
│   │   ├── rule_engine.ex         # GenServer: rule evaluation
│   │   └── router.ex              # Routes events to recipients
│   ├── workers/
│   │   ├── event_processor.ex     # GenServer: process incoming events
│   │   ├── websocket_worker.ex    # Task: WebSocket delivery
│   │   ├── email_worker.ex        # Task: Email delivery
│   │   └── webhook_worker.ex      # Task: Webhook delivery
│   └── application.ex
│
└── erp_notification_web/
    ├── channels/
    │   ├── user_socket.ex
    │   └── notification_channel.ex
    ├── live/
    │   ├── inbox_live.ex
    │   ├── admin/
    │   │   ├── dashboard_live.ex
    │   │   ├── events_live.ex
    │   │   └── templates_live.ex
    │   └── components/
    │       ├── notification_badge.ex
    │       └── notification_item.ex
    ├── controllers/
    │   └── event_controller.ex
    └── router.ex
```

---

## 8. OTP Supervision Tree

```elixir
ErpNotification.Application
├── ErpNotification.Repo
├── ErpNotificationWeb.Endpoint
├── Phoenix.PubSub (ErpNotification.PubSub)
├── Phoenix.Presence (ErpNotification.Presence)
└── ErpNotification.WorkerSupervisor
    ├── ErpNotification.Workers.EventProcessor   # GenServer
    ├── ErpNotification.Workers.EmailWorker      # GenServer + queue
    └── ErpNotification.Workers.WebhookWorker    # GenServer + queue
```

---

## 9. Phoenix Channel API

### WebSocket Topics
```
notifications:user:{user_id}    → Personal notifications
notifications:role:{role_name}  → Role-based broadcast
notifications:system            → System-wide alerts
```

### Server → Client Events
```json
// new_notification
{
  "event": "new_notification",
  "payload": {
    "id": 123,
    "title": "Stok Kritis: Barang A",
    "body": "Stok Barang A tersisa 5 unit",
    "priority": "high",
    "type": "stock.critical",
    "action_url": "/inventory/items/42",
    "inserted_at": "2026-05-20T16:00:00Z"
  }
}

// unread_count_updated
{
  "event": "unread_count_updated",
  "payload": { "count": 7 }
}
```

### Client → Server Events
```json
{ "event": "mark_read",     "payload": { "notification_id": 123 } }
{ "event": "mark_all_read", "payload": {} }
```

---

## 10. REST API Endpoints

```
# Event Ingestion
POST   /api/v1/events
GET    /api/v1/events          (admin)
GET    /api/v1/events/:id      (admin)

# Notifications (User)
GET    /api/v1/notifications
GET    /api/v1/notifications/unread
PATCH  /api/v1/notifications/:id/read
POST   /api/v1/notifications/read_all

# Preferences
GET    /api/v1/preferences
PUT    /api/v1/preferences

# Admin
GET    /api/v1/admin/stats
GET    /api/v1/admin/templates
POST   /api/v1/admin/templates
PUT    /api/v1/admin/templates/:id
```

---

## 11. Katalog Event Types

| Module | Event Type | Deskripsi | Priority |
|--------|-----------|-----------|----------|
| Inventory | `stock.critical` | Stok di bawah minimum | high |
| Inventory | `stock.out` | Stok habis | critical |
| Finance | `invoice.due` | Invoice jatuh tempo | high |
| Finance | `invoice.overdue` | Invoice melewati jatuh tempo | critical |
| Finance | `payment.received` | Pembayaran diterima | medium |
| Purchase | `po.pending_approval` | PO menunggu approval | high |
| Purchase | `po.approved` | PO disetujui | medium |
| Sales | `order.new` | Order baru masuk | medium |
| Sales | `order.shipped` | Pesanan dikirim | medium |
| HR | `leave.pending_approval` | Cuti menunggu approval | medium |
| System | `system.error` | Error kritis | critical |
| System | `system.health` | Laporan kesehatan | low |

---

## 12. Non-Functional Requirements

### Performance
- Latency: **P95 < 200ms**, P99 < 500ms
- Throughput: min **5.000 events/menit**
- Concurrent WebSocket: **10.000+**
- Database query: < 50ms untuk semua read ops

### Reliability
- Uptime: **99.9%** SLA
- Delivery guarantee dengan retry mechanism
- Max 3 retry dengan exponential backoff
- Dead letter queue untuk notifikasi gagal

### Security (sesuai `.agent/rules/elixir_phoenix_rules.md`)
- Autentikasi WebSocket via JWT (Guardian)
- Rate limiting pada event ingestion API
- Row-level security: user akses notifikasi miliknya saja
- CSRF protection aktif
- Secrets via environment variables

---

## 13. Dependencies (`mix.exs`)

```elixir
defp deps do
  [
    {:phoenix, "~> 1.7"},
    {:phoenix_ecto, "~> 4.4"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"},
    {:phoenix_live_view, "~> 0.20"},
    {:phoenix_live_dashboard, "~> 0.8"},
    {:swoosh, "~> 1.5"},
    {:finch, "~> 0.13"},
    {:httpoison, "~> 2.0"},
    {:jason, "~> 1.2"},
    {:plug_cowboy, "~> 2.5"},
    {:guardian, "~> 2.3"},
    {:hammer, "~> 6.1"},
    {:telemetry_metrics, "~> 0.6"},
    {:telemetry_poller, "~> 1.0"},
    # Test only
    {:ex_machina, "~> 2.7", only: :test},
    {:faker, "~> 0.17", only: :test},
    {:mox, "~> 1.0", only: :test}
  ]
end
```

---

## 14. Roadmap Implementasi (5 Phase)

### Phase 1 — Foundation (Minggu 1-2)
- [ ] Setup Phoenix project
- [ ] Database migrations (semua tabel)
- [ ] Ecto schemas & changesets
- [ ] Basic contexts: Events, Notifications
- [ ] REST API: event ingestion
- [ ] Unit tests semua contexts

### Phase 2 — Realtime Core (Minggu 3-4)
- [ ] Phoenix.Channel setup
- [ ] Phoenix.Presence integration
- [ ] WebSocket delivery worker (GenServer)
- [ ] Rule Engine (GenServer)
- [ ] Event Processor: consume & dispatch
- [ ] Integration tests WebSocket flow

### Phase 3 — Multi-Channel (Minggu 5-6)
- [ ] Email worker (Swoosh)
- [ ] Webhook worker (HTTPoison)
- [ ] Retry mechanism + exponential backoff
- [ ] Dead letter handling
- [ ] Delivery audit trail

### Phase 4 — User Interface (Minggu 7-8)
- [ ] LiveView: Notification Inbox
- [ ] LiveView: Notification Badge (realtime)
- [ ] LiveView: Preferences management
- [ ] Admin LiveView: Dashboard & Analytics
- [ ] Admin LiveView: Template Manager

### Phase 5 — Production Hardening (Minggu 9-10)
- [ ] JWT auth (Guardian)
- [ ] Rate limiting (Hammer)
- [ ] Performance & load testing
- [ ] Docker & release config
- [ ] Monitoring: LiveDashboard + Telemetry
- [ ] OpenAPI documentation

---

## 15. Testing Strategy

Mengikuti `.agent/rules/elixir_phoenix_rules.md`:

| Layer | Tool | Target |
|-------|------|--------|
| Unit Tests | ExUnit + ExMachina | 90%+ |
| Integration Tests | Phoenix.ConnTest | 85%+ |
| Channel Tests | Phoenix.ChannelTest | 85%+ |
| LiveView Tests | Phoenix.LiveViewTest | 80%+ |
| Load Tests | k6 | Throughput & latency |

---

## 16. Acceptance Criteria

| # | Kriteria | Status |
|---|---------|--------|
| AC-01 | Event dikirim via API → notifikasi muncul di browser < 500ms | ⬜ |
| AC-02 | 10.000 WebSocket connections simultan tanpa degradasi | ⬜ |
| AC-03 | Email terkirim untuk event priority `critical` dan `high` | ⬜ |
| AC-04 | User dapat mark read/unread, badge update realtime | ⬜ |
| AC-05 | Semua delivery tercatat di audit trail | ⬜ |
| AC-06 | Admin dapat CRUD template notifikasi | ⬜ |
| AC-07 | User dapat atur preferensi per tipe notifikasi | ⬜ |
| AC-08 | Notifikasi gagal di-retry max 3x dengan backoff | ⬜ |
| AC-09 | Rate limit aktif: max 1000 events/menit per source | ⬜ |
| AC-10 | Test coverage > 85% semua contexts | ⬜ |

---

## 17. Glossary

| Term | Definisi |
|------|---------|
| Event | Kejadian bisnis dari modul ERP |
| Notification | Pesan yang digenerate dari event, ditargetkan ke user |
| Template | Blueprint untuk membuat notification dari event type |
| Rule | Aturan yang menentukan siapa yang dinotifikasi |
| Channel | Medium pengiriman (WebSocket, Email, Webhook) |
| Delivery | Satu upaya pengiriman notifikasi melalui satu channel |
| Priority | Tingkat urgensi: critical > high > medium > low |

---

> *PRD ini mengikuti coding conventions dari `.agent/rules/elixir_phoenix_rules.md`, pattern dari `.agent/skills/`, dan workflow dari `.agent/workflows/`.*

**Built with ❤️ using Elixir · Phoenix · PostgreSQL**
