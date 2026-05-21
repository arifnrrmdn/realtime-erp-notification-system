# 📋 Implementation Plan
# Realtime ERP Notification System

**Based on PRD v1.0.0**  
**Tech Stack:** Elixir · Phoenix Framework · PostgreSQL  
**Timeline:** 10 Weeks (5 Phases)

---

## Phase 1 — Foundation (Week 1-2)

### 1.1 Setup Phoenix Project Structure
- Initialize new Phoenix project: `mix phx.new erp_notification --app erp_notification --module ErpNotification`
- Configure database in `config/dev.exs` and `config/test.exs`
- Add dependencies from PRD section 13 to `mix.exs`
- Run `mix deps.get`
- Setup directory structure per PRD section 7

### 1.2 Database Migrations
Create migrations in order:
1. `notification_events` - Section 6.1
2. `notifications` - Section 6.2
3. `notification_deliveries` - Section 6.3
4. `notification_templates` - Section 6.4
5. `user_notification_preferences` - Section 6.5

Run: `mix ecto.migrate`

### 1.3 Ecto Schemas & Changesets
Create schemas in `lib/erp_notification/`:
- `events/event.ex` - Schema for notification_events
- `notifications/notification.ex` - Schema for notifications
- `notifications/delivery.ex` - Schema for notification_deliveries
- `notifications/template.ex` - Schema for notification_templates
- `notifications/preference.ex` - Schema for user_notification_preferences

Each schema should have:
- Proper field types matching SQL schema
- Changesets with validation
- JSONB field casting for payload/metadata

### 1.4 Basic Contexts
Create context modules:
- `ErpNotification.Events` - CRUD for notification_events
- `ErpNotification.Notifications` - CRUD for notifications, deliveries, templates, preferences

Key functions:
- `Events.create_event/1`
- `Events.list_events/1` (with filters)
- `Notifications.create_notification/1`
- `Notifications.mark_read/1`
- `Notifications.get_unread_count/1`

### 1.5 REST API - Event Ingestion
Create controller: `lib/erp_notification_web/controllers/event_controller.ex`
- POST `/api/v1/events` - Accept event payload
- Validate event_type against catalog (PRD section 11)
- Store in notification_events table
- Return 201 with event_id

Add routes in `lib/erp_notification_web/router.ex`:
```elixir
scope "/api/v1" do
  post "/events", EventController, :create
end
```

### 1.6 Unit Tests
Create tests in `test/erp_notification/`:
- `events_test.exs` - Test Events context
- `notifications_test.exs` - Test Notifications context
- `event_controller_test.exs` - Test API endpoint

Target: 90%+ coverage

---

## Phase 2 — Realtime Core (Week 3-4)

### 2.1 Phoenix.Channel Setup
Create files:
- `lib/erp_notification_web/channels/user_socket.ex` - WebSocket connection handler
- `lib/erp_notification_web/channels/notification_channel.ex` - Notification broadcast logic

Topics (per PRD section 9):
- `notifications:user:{user_id}` - Personal notifications
- `notifications:role:{role_name}` - Role-based broadcast
- `notifications:system` - System-wide alerts

### 2.2 Phoenix.Presence Integration
Add to `user_socket.ex`:
```elixir
use Phoenix.Presence,
  otp_app: :erp_notification,
  pubsub_server: ErpNotification.PubSub
```

Track user online status for real-time delivery optimization

### 2.3 WebSocket Delivery Worker (GenServer)
Create: `lib/erp_notification/workers/websocket_worker.ex`
- Subscribe to notification events
- Push to appropriate Phoenix channels
- Handle offline users (queue for later)
- Use Phoenix.PubSub for broadcast

### 2.4 Rule Engine (GenServer)
Create: `lib/erp_notification/rules/rule_engine.ex`
- Load active templates from database
- Evaluate rules based on event_type and payload
- Determine target users/roles
- Apply user preferences
- Return notification recipients

### 2.5 Event Processor (GenServer)
Create: `lib/erp_notification/workers/event_processor.ex`
- Consume unprocessed events from database
- Call Rule Engine to determine recipients
- Create notification records
- Dispatch to delivery workers
- Mark events as processed
- Add to OTP supervision tree

### 2.6 Integration Tests
Create: `test/erp_notification_web/channels/notification_channel_test.exs`
- Test WebSocket connection
- Test event subscription
- Test notification broadcast
- Test presence tracking

---

## Phase 3 — Multi-Channel (Week 5-6)

### 3.1 Email Worker (Swoosh)
Create: `lib/erp_notification/workers/email_worker.ex`
- Use Swoosh for email delivery
- Configure SMTP/SES in `config/config.exs`
- Render email templates from notification_templates
- Send based on priority (critical, high)
- Queue with GenServer for async delivery

### 3.2 Webhook Worker (HTTPoison)
Create: `lib/erp_notification/workers/webhook_worker.ex`
- Use HTTPoison for HTTP POST
- Configure webhook URLs per user/system
- Send notification payload as JSON
- Handle response codes
- Queue with GenServer for async delivery

### 3.3 Retry Mechanism
Implement in delivery workers:
- Max 3 retries per delivery
- Exponential backoff: 1s, 5s, 25s
- Update `notification_deliveries.attempt_count`
- Update `notification_deliveries.last_attempted_at`
- Mark status as 'failed' after max retries

### 3.4 Dead Letter Queue
Create: `lib/erp_notification/workers/dead_letter_worker.ex`
- Monitor failed deliveries
- Move to separate table or queue
- Alert admin for manual intervention
- Provide retry mechanism

### 3.5 Delivery Audit Trail
Ensure all delivery attempts logged:
- Update `notification_deliveries` table
- Track status: pending, sent, failed
- Store error messages
- Provide admin query interface

---

## Phase 4 — User Interface (Week 7-8)

### 4.1 LiveView - Notification Inbox
Create: `lib/erp_notification_web/live/inbox_live.ex`
- List all notifications for current user
- Filter by read/unread, type, priority
- Search functionality
- Mark as read on click
- Pagination for large lists
- Real-time updates via Phoenix.LiveView

Template: `lib/erp_notification_web/live/inbox_live.html.heex`

### 4.2 LiveView Component - Notification Badge
Create: `lib/erp_notification_web/live/components/notification_badge.ex`
- Display unread count in navbar
- Update in real-time via PubSub
- Click to open inbox
- Show preview on hover

### 4.3 LiveView - Preferences Management
Create: `lib/erp_notification_web/live/preferences_live.ex`
- List all event types
- Per-type channel selection (WebSocket, Email, Webhook)
- Quiet hours configuration
- Digest mode toggle
- Save to `user_notification_preferences`

### 4.4 Admin LiveView - Dashboard & Analytics
Create: `lib/erp_notification_web/live/admin/dashboard_live.ex`
- Delivery statistics (success rate, failure rate)
- Channel performance metrics
- Event volume over time
- Top event types
- Active users count
- Use Telemetry metrics

### 4.5 Admin LiveView - Template Manager
Create: `lib/erp_notification_web/live/admin/templates_live.ex`
- CRUD for notification_templates
- Preview template rendering
- Activate/deactivate templates
- Test template with sample payload

---

## Phase 5 — Production Hardening (Week 9-10)

### 5.1 JWT Authentication (Guardian)
Add Guardian to `mix.exs`:
```elixir
{:guardian, "~> 2.3"}
```

Setup:
- Create `ErpNotification.Guardian` module
- Implement JWT token generation/verification
- Add authentication plug to API routes
- Secure WebSocket connections with token

### 5.2 Rate Limiting (Hammer)
Add Hammer to `mix.exs`:
```elixir
{:hammer, "~> 6.1"}
```

Implement:
- Rate limit event ingestion API: 1000 events/min per source
- Rate limit WebSocket connections: 10 per second per IP
- Add plug to router
- Configure Redis backend for distributed rate limiting

### 5.3 Performance & Load Testing
Setup k6 for load testing:
- Test 1: 10,000 concurrent WebSocket connections
- Test 2: 5,000 events/minute throughput
- Test 3: End-to-end latency (target P99 < 500ms)
- Test 4: Database query performance (target < 50ms)

Create: `load_tests/` directory with k6 scripts

### 5.4 Docker & Release Configuration
Create `Dockerfile`:
- Multi-stage build
- Alpine-based final image
- Expose port 4000
- Environment variables for config

Create `docker-compose.yml`:
- Application service
- PostgreSQL service
- Redis service (for rate limiting)

Configure releases in `mix.exs`:
- Use `mix release` for production builds
- Setup runtime configuration

### 5.5 Monitoring - LiveDashboard + Telemetry
Add to `mix.exs`:
```elixir
{:phoenix_live_dashboard, "~> 0.8"}
{:telemetry_metrics, "~> 0.6"}
{:telemetry_poller, "~> 1.0"}
```

Setup:
- Enable LiveDashboard in endpoint
- Create custom Telemetry metrics
- Monitor: request latency, DB query time, WebSocket connections, queue sizes
- Setup external monitoring (e.g., Datadog, New Relic)

### 5.6 OpenAPI Documentation
Add OpenAPI Spex to `mix.exs`:
```elixir
{:open_api_spex, "~> 3.16"}
```

Generate documentation:
- Document all REST API endpoints
- Include request/response schemas
- Authentication requirements
- Serve at `/api/swagger`

---

## Acceptance Criteria Verification

Per PRD section 16, verify each AC:

| AC | Verification Method |
|----|---------------------|
| AC-01 | Load test: measure latency from API to WebSocket |
| AC-02 | k6 test: 10K WebSocket connections |
| AC-03 | Integration test: email sent for critical/high priority |
| AC-04 | LiveView test: mark read updates badge |
| AC-05 | Query notification_deliveries table |
| AC-06 | Admin UI test: CRUD templates |
| AC-07 | Preferences UI test: save per-type settings |
| AC-08 | Unit test: retry logic with backoff |
| AC-09 | Integration test: rate limit enforcement |
| AC-10 | Run `mix test --cover` |

---

## Dependencies Installation

```bash
# Add to mix.exs
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
    {:open_api_spex, "~> 3.16"},
    # Test only
    {:ex_machina, "~> 2.7", only: :test},
    {:faker, "~> 0.17", only: :test},
    {:mox, "~> 1.0", only: :test}
  ]
end
```

---

## Testing Strategy

Per PRD section 15:

### Unit Tests (ExUnit + ExMachina)
- Target: 90%+ coverage
- Test all contexts, schemas, changesets
- Mock external dependencies (Mox)

### Integration Tests (Phoenix.ConnTest)
- Target: 85%+ coverage
- Test API endpoints
- Test database transactions
- Test authentication flows

### Channel Tests (Phoenix.ChannelTest)
- Target: 85%+ coverage
- Test WebSocket connections
- Test PubSub broadcasts
- Test presence tracking

### LiveView Tests (Phoenix.LiveViewTest)
- Target: 80%+ coverage
- Test UI interactions
- Test real-time updates
- Test form submissions

### Load Tests (k6)
- Test throughput and latency
- Test concurrent connections
- Test resource limits

---

## Success Metrics

Per PRD section 2:

| Metric | Target | Measurement |
|--------|--------|-------------|
| Latency P99 | < 500ms | Load test |
| Delivery Rate | 99.99% | Audit trail query |
| Concurrent WebSocket | 10,000+ | k6 test |
| Active Channels | 3 (v1.0) | Code review |
| Event Tracking | 100% | Database query |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| WebSocket connection drops | Implement auto-reconnect on client |
| Email delivery failures | Retry mechanism + dead letter queue |
| Database performance | Add indexes, optimize queries, connection pooling |
| High event volume | Queue with backpressure, rate limiting |
| Security vulnerabilities | Follow OWASP guidelines, regular audits |

---

## Next Steps

1. Review and approve this implementation plan
2. Begin Phase 1: Foundation
3. Track progress using todo list
4. Update plan as needed during implementation

---

**Last Updated:** 2026-05-21  
**Status:** Ready for Implementation
