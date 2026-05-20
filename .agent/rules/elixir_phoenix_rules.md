# Elixir + Phoenix + PostgreSQL Development Rules

## Code Style & Conventions
- Use snake_case for variables, functions, and module attributes
- Use PascalCase for module names
- Use SCREAMING_SNAKE_CASE for constants
- Follow Elixir formatter rules (mix format)
- Use pattern matching instead of conditional statements when possible
- Prefer pipe operator |> for data transformations
- Use GenServer for stateful processes
- Use Supervisor for fault tolerance

## Phoenix Conventions
- Controllers should be thin, business logic in contexts
- Use contexts to group related functionality
- Follow RESTful routing conventions
- Use Phoenix.LiveView for interactive features
- Validate data with Ecto changesets
- Use Phoenix.PubSub for real-time features

## Database (PostgreSQL)
- Use Ecto migrations for schema changes
- Define schemas with proper types and constraints
- Use Ecto.Changeset for data validation
- Prefer database constraints over application validations
- Use indexes for frequently queried columns
- Use transactions for multi-step operations

## Testing
- Write tests for all public functions
- Use ExUnit for unit tests
- Use Phoenix.ConnTest for controller tests
- Use Phoenix.LiveViewTest for LiveView tests
- Mock external dependencies
- Aim for high test coverage

## Security
- Validate all user inputs
- Use CSRF protection
- Sanitize HTML output
- Use proper authentication and authorization
- Store secrets in environment variables
- Use HTTPS in production