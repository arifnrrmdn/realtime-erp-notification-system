# Elixir Phoenix PostgreSQL Project

A robust, scalable web application built with Elixir, Phoenix Framework, and PostgreSQL database. This project follows modern development practices and provides a solid foundation for building high-performance, fault-tolerant web applications.

## 🚀 Tech Stack

- **[Elixir](https://elixir-lang.org/)** - Dynamic, functional programming language
- **[Phoenix Framework](https://phoenixframework.org/)** - Productive web framework
- **[PostgreSQL](https://postgresql.org/)** - Advanced open source database
- **[Ecto](https://hexdocs.pm/ecto/)** - Database wrapper and query generator

## ✨ Features

- **High Performance**: Built on the Actor model with lightweight processes
- **Fault Tolerance**: Supervisor trees ensure system resilience
- **Real-time**: Phoenix Channels for WebSocket connections
- **Scalable**: Horizontal scaling with distributed Elixir
- **Type Safety**: Pattern matching and compile-time checks
- **Database**: Advanced PostgreSQL features with Ecto ORM

## 📋 Prerequisites

Before running this project, make sure you have the following installed:

- **Elixir** >= 1.14
- **Erlang/OTP** >= 25
- **Phoenix** >= 1.7
- **PostgreSQL** >= 14
- **Node.js** >= 18 (for asset compilation, if needed)

### Installation Guide

#### macOS
```bash
# Using Homebrew
brew install elixir postgresql

# Install Phoenix
mix archive.install hex phx_new
```

#### Ubuntu/Debian
```bash
# Add Erlang Solutions repository
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update

# Install Elixir and PostgreSQL
sudo apt-get install elixir postgresql postgresql-contrib

# Install Phoenix
mix archive.install hex phx_new
```

## 🛠️ Setup & Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd <project-name>
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Database setup**
   ```bash
   # Create database
   mix ecto.create
   
   # Run migrations
   mix ecto.migrate
   
   # Seed database (optional)
   mix run priv/repo/seeds.exs
   ```

4. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

   Or start with interactive Elixir console:
   ```bash
   iex -S mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) in your browser.

## 🏗️ Project Structure

```
├── .agent/                 # Agent configuration and workflows
│   ├── rules/             # Development rules and conventions
│   ├── skills/            # Technical skills and best practices
│   └── workflows/         # Development workflows
├── config/                # Application configuration
├── lib/
│   ├── project_name/      # Business logic and contexts
│   └── project_name_web/  # Web interface (controllers, views, etc.)
├── priv/
│   ├── repo/             # Database migrations and seeds
│   └── static/           # Static assets
├── test/                 # Test files
└── mix.exs              # Project dependencies and configuration
```

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/project_name/accounts_test.exs

# Run tests in watch mode (requires mix_test_watch)
mix test.watch
```

## 📊 Database Operations

### Migrations
```bash
# Create a new migration
mix ecto.gen.migration create_users

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database
mix ecto.reset
```

### Generating Resources
```bash
# Generate context with schema
mix phx.gen.context Accounts User users name:string email:string:unique

# Generate JSON API
mix phx.gen.json Catalog Product products name:string price:decimal

# Generate LiveView (for interactive features)
mix phx.gen.live Blog Post posts title:string content:text
```

## 🚀 Deployment

### Production Build
```bash
# Set production environment
export MIX_ENV=prod

# Install production dependencies
mix deps.get --only prod

# Compile the application
mix compile

# Create release
mix release
```

### Docker Deployment
```dockerfile
# Example Dockerfile structure
FROM elixir:1.14-alpine AS build
# ... build steps

FROM alpine:3.17 AS runtime
# ... runtime setup
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file or set the following environment variables:

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost/database_name

# Phoenix
SECRET_KEY_BASE=your_secret_key_base
PHX_HOST=localhost
PORT=4000

# Environment
MIX_ENV=dev
```

### Development Configuration
Key configuration files:
- `config/dev.exs` - Development environment
- `config/test.exs` - Test environment  
- `config/prod.exs` - Production environment
- `config/runtime.exs` - Runtime configuration

## 📈 Performance & Monitoring

### Built-in Tools
- **Phoenix LiveDashboard** - Real-time metrics and insights
- **Telemetry** - Application metrics and monitoring
- **Logger** - Structured logging

### Recommended Monitoring
- **AppSignal** or **New Relic** for APM
- **Sentry** for error tracking
- **Prometheus + Grafana** for metrics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow the coding standards in `.agent/rules/`
- Write tests for new features
- Update documentation as needed
- Use conventional commit messages

## 📝 Code Style

This project follows Elixir community standards:
- Use `mix format` for code formatting
- Follow naming conventions (snake_case, PascalCase)
- Write documentation with `@doc` and `@spec`
- Use pattern matching over conditional statements

## 🔒 Security

- Input validation with Ecto changesets
- CSRF protection enabled
- Secure headers configured
- Environment-based secrets management
- Regular dependency updates

## 📚 Resources

### Documentation
- [Elixir Documentation](https://hexdocs.pm/elixir/)
- [Phoenix Framework Guides](https://hexdocs.pm/phoenix/)
- [Ecto Documentation](https://hexdocs.pm/ecto/)
- [PostgreSQL Documentation](https://postgresql.org/docs/)

### Learning Resources
- [Elixir School](https://elixirschool.com/)
- [Phoenix LiveView Course](https://pragmaticstudio.com/phoenix-liveview)
- [Learn Functional Programming with Elixir](https://pragprog.com/titles/cdc-elixir/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the [Phoenix Forum](https://elixirforum.com/c/phoenix-forum/)
- Join the [Elixir Slack](https://elixir-slackin.herokuapp.com/)

---

**Built with ❤️ using Elixir and Phoenix Framework**