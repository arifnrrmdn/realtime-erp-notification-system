# Realtime ERP Notification System

A high-performance, real-time notification service for ERP systems built with Elixir, Phoenix Framework, and PostgreSQL. This system captures events from various ERP modules and delivers notifications to the right users through the right channels at the right time.

## 🚀 Features

### Core Capabilities
- **Real-time Event Ingestion**: Accept events from ERP modules via REST API or internal PubSub
- **Intelligent Rule Engine**: Determine notification recipients based on configurable rules and templates
- **Multi-Channel Delivery**: Support for WebSocket, Email, and Webhook delivery channels
- **Priority System**: Four priority levels (critical, high, medium, low) with appropriate routing
- **Deduplication & Batching**: Prevent notification spam with smart deduplication and batching

### Real-time Delivery
- **WebSocket Channels**: Push notifications instantly via Phoenix Channels
- **User & Role Channels**: Personal channels (`notifications:user:{id}`) and role-based broadcasts
- **Presence Tracking**: Track user online status for optimized delivery
- **Live UI Updates**: Real-time badge counters and inbox updates

### User Interface
- **Notification Inbox**: Browse, filter, and search notifications with Phoenix LiveView
- **Read/Unread Management**: Mark notifications as read with real-time sync
- **Notification Preferences**: Configure channel preferences per notification type
- **Quiet Hours**: Set time windows to reduce notification noise

### Admin Panel
- **Event Log Viewer**: Monitor all incoming events and delivery status
- **Template Manager**: CRUD interface for notification templates
- **Rule Configuration**: Manage routing rules and recipient logic
- **Analytics Dashboard**: Delivery statistics, engagement metrics, and channel performance

## 🛠 Tech Stack

- **Language**: Elixir 1.14+
- **Web Framework**: Phoenix 1.7.10
- **Database**: PostgreSQL with Ecto 3.10
- **Real-time**: Phoenix Channels & Phoenix LiveView 0.20.1
- **Email**: Swoosh 1.3 with Finch 0.13
- **HTTP Client**: HTTPoison 2.0
- **Authentication**: Guardian 2.3 (JWT)
- **Rate Limiting**: Hammer 6.1
- **Testing**: ExUnit, ExMachina, Faker, Mox
- **Monitoring**: Telemetry Metrics, Phoenix LiveDashboard 0.8.2

## 📋 Prerequisites

- Elixir 1.14 or higher
- Erlang/OTP 25 or higher
- PostgreSQL 14 or higher
- Node.js 18+ (for asset compilation)
- Redis (optional, for distributed rate limiting)

## 🔧 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/realtime-erp-notification-system.git
cd realtime-erp-notification-system
```

### 2. Install Dependencies

```bash
mix deps.get
cd assets && npm install && cd ..
```

### 3. Configure Database

Edit `config/dev.exs` and `config/test.exs` to set your PostgreSQL credentials:

```elixir
config :erp_notification, ErpNotification.Repo,
  username: "postgres",
  password: "postgres",
  database: "erp_notification_dev",
  hostname: "localhost",
  port: 5432
```

### 4. Create and Migrate Database

```bash
mix ecto.create
mix ecto.migrate
```

### 5. Seed Database (Optional)

```bash
mix run priv/repo/seeds.exs
```

### 6. Start the Server

```bash
mix phx.server
```

The application will be available at `http://localhost:4000`

## 📖 Usage

### Sending Events

Send events to the notification system via the REST API:

```bash
curl -X POST http://localhost:4000/api/v1/events \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "stock.critical",
    "source": "inventory",
    "payload": {
      "item_id": 42,
      "item_name": "Barang A",
      "current_stock": 5,
      "minimum_stock": 10
    },
    "priority": "high"
  }'
```

### WebSocket Connection

Connect to the notification channel using JavaScript:

```javascript
let socket = new Socket("ws://localhost:4000/socket", {
  params: { token: "your-jwt-token" }
});

socket.connect();

let channel = socket.channel("notifications:user:123", {});
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp); })
  .receive("error", resp => { console.log("Unable to join", resp); });

channel.on("new_notification", payload => {
  console.log("New notification:", payload);
});
```

### Available Event Types

| Module | Event Type | Description | Priority |
|--------|-----------|-------------|----------|
| Inventory | `stock.critical` | Stock below minimum | high |
| Inventory | `stock.out` | Stock exhausted | critical |
| Finance | `invoice.due` | Invoice due date | high |
| Finance | `invoice.overdue` | Invoice past due | critical |
| Finance | `payment.received` | Payment received | medium |
| Purchase | `po.pending_approval` | PO awaiting approval | high |
| Purchase | `po.approved` | PO approved | medium |
| Sales | `order.new` | New order received | medium |
| Sales | `order.shipped` | Order shipped | medium |
| HR | `leave.pending_approval` | Leave request pending | medium |
| System | `system.error` | Critical system error | critical |
| System | `system.health` | System health report | low |

## 🏗 Architecture

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

## 📊 API Endpoints

### Event Ingestion
- `POST /api/v1/events` - Submit a new event
- `GET /api/v1/events` - List all events (admin)
- `GET /api/v1/events/:id` - Get event details (admin)

### Notifications (User)
- `GET /api/v1/notifications` - List user notifications
- `GET /api/v1/notifications/unread` - Get unread notifications
- `PATCH /api/v1/notifications/:id/read` - Mark notification as read
- `POST /api/v1/notifications/read_all` - Mark all notifications as read

### Preferences
- `GET /api/v1/preferences` - Get user notification preferences
- `PUT /api/v1/preferences` - Update user preferences

### Admin
- `GET /api/v1/admin/stats` - Get system statistics
- `GET /api/v1/admin/templates` - List notification templates
- `POST /api/v1/admin/templates` - Create a new template
- `PUT /api/v1/admin/templates/:id` - Update a template
- `DELETE /api/v1/admin/templates/:id` - Delete a template

## 🧪 Testing

### Run All Tests

```bash
mix test
```

### Run with Coverage

```bash
mix test --cover
```

### Run Specific Test File

```bash
mix test test/erp_notification/events_test.exs
```

### Test Targets
- Unit Tests: 90%+ coverage (ExUnit + ExMachina)
- Integration Tests: 85%+ coverage (Phoenix.ConnTest)
- Channel Tests: 85%+ coverage (Phoenix.ChannelTest)
- LiveView Tests: 80%+ coverage (Phoenix.LiveViewTest)

## 🔐 Security

- **JWT Authentication**: WebSocket connections secured with Guardian JWT tokens
- **Rate Limiting**: Event ingestion API limited to 1000 events/minute per source
- **Row-Level Security**: Users can only access their own notifications
- **CSRF Protection**: Enabled for all state-changing operations
- **Environment Variables**: Sensitive configuration via environment variables

## 📈 Performance Targets

- **Latency**: P95 < 200ms, P99 < 500ms from event to delivery
- **Throughput**: Minimum 5,000 events/minute
- **Concurrent Connections**: 10,000+ WebSocket connections
- **Database Queries**: < 50ms for all read operations
- **Uptime**: 99.9% SLA

## 🚢 Deployment

### Using Mix Release

```bash
mix release
_build/dev/rel/erp_notification/bin/erp_notification start
```

### Using Docker

Build the Docker image:

```bash
docker build -t erp-notification .
```

Run with Docker Compose:

```bash
docker-compose up -d
```

### Environment Variables

Configure the following environment variables for production:

```bash
DATABASE_URL=postgresql://user:pass@host:5432/dbname
SECRET_KEY_BASE=your-secret-key-base
GUARDIAN_SECRET_KEY=your-jwt-secret
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
```

## 📚 Documentation

- [Product Requirements Document](PRD.md) - Detailed product specification
- [Implementation Plan](IMPLEMENTATION_PLAN.md) - Development roadmap and phases

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Elixir and Phoenix coding conventions
- Write tests for all new features
- Ensure test coverage remains above 85%
- Update documentation as needed
- Run `mix format` before committing

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- **Project Lead**: [Your Name]
- **Tech Stack**: Elixir · Phoenix · PostgreSQL

## 🙏 Acknowledgments

- Built with [Phoenix Framework](https://www.phoenixframework.org/)
- Real-time capabilities powered by [Phoenix Channels](https://hexdocs.pm/phoenix/channels.html)
- UI built with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)

---

**Version**: 0.1.0  
**Last Updated**: 2026-05-21  
**Status**: Development
