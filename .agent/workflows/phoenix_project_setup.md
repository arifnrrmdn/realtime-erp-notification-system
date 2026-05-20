# Phoenix Project Setup Workflow

## 1. Project Initialization

### Create New Phoenix Project
```bash
# Install Phoenix if not already installed
mix archive.install hex phx_new

# Create new project (without React/frontend)
mix phx.new project_name --no-assets --no-html
# or for API only
mix phx.new project_name --no-assets --no-html --no-live

cd project_name
```

### Database Setup
```bash
# Configure database in config/dev.exs and config/test.exs
# Create database
mix ecto.create

# Run initial migration
mix ecto.migrate
```

## 2. Project Structure Setup

### Create Core Contexts
```bash
# Generate context with schema
mix phx.gen.context Accounts User users name:string email:string:unique

# Generate JSON API
mix phx.gen.json Catalog Product products name:string price:decimal description:text

# Generate LiveView (if using HTML)
mix phx.gen.live Blog Post posts title:string content:text published:boolean
```

### Setup Authentication (Optional)
```bash
# Add phx_gen_auth dependency
mix phx.gen.auth Accounts User users
```

## 3. Configuration

### Environment Configuration
- Configure database connections
- Set up environment variables
- Configure Phoenix endpoint
- Set up logging levels

### Dependencies Management
```bash
# Add common dependencies to mix.exs
# - {:jason, "~> 1.4"} for JSON
# - {:cors_plug, "~> 3.0"} for CORS
# - {:ex_machina, "~> 2.7", only: :test} for factories

mix deps.get
```

## 4. Development Workflow

### Running the Application
```bash
# Start Phoenix server
mix phx.server

# Start with IEx console
iex -S mix phx.server
```

### Database Operations
```bash
# Create migration
mix ecto.gen.migration create_table_name

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback

# Reset database
mix ecto.reset
```

### Testing
```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/project_name/accounts_test.exs
```

## 5. Production Deployment

### Build Release
```bash
# Set production environment
export MIX_ENV=prod

# Install dependencies
mix deps.get --only prod

# Compile assets (if any)
mix assets.deploy

# Create release
mix release
```

### Database Migration in Production
```bash
# Run migrations in production
_build/prod/rel/project_name/bin/project_name eval "ProjectName.Release.migrate"
```