# PostgreSQL + Ecto Database Workflow

## 1. Schema Design

### Define Ecto Schema
```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean, default: true

    has_many :posts, MyApp.Blog.Post
    belongs_to :role, MyApp.Accounts.Role

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age, :active])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
```

### Create Migration
```bash
mix ecto.gen.migration create_users
```

```elixir
defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :age, :integer
      add :active, :boolean, default: true
      add :role_id, references(:roles, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:role_id])
  end
end
```

## 2. Context Implementation

### Create Context Module
```elixir
defmodule MyApp.Accounts do
  import Ecto.Query, warn: false
  alias MyApp.Repo
  alias MyApp.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end
end
```

## 3. Query Patterns

### Basic Queries
```elixir
# Get all records
Repo.all(User)

# Get by ID
Repo.get(User, id)
Repo.get!(User, id)  # Raises if not found

# Get by field
Repo.get_by(User, email: "user@example.com")

# First/Last
Repo.one(from u in User, order_by: u.inserted_at, limit: 1)
```

### Complex Queries
```elixir
# With associations
query = from u in User,
  join: p in assoc(u, :posts),
  where: u.active == true,
  preload: [posts: p],
  select: u

Repo.all(query)

# Aggregations
query = from u in User,
  where: u.active == true,
  group_by: u.role_id,
  select: {u.role_id, count(u.id)}

Repo.all(query)
```

## 4. Database Operations

### Transactions
```elixir
Repo.transaction(fn ->
  {:ok, user} = create_user(%{name: "John", email: "john@example.com"})
  {:ok, post} = create_post(%{title: "Hello", user_id: user.id})
  {user, post}
end)
```

### Bulk Operations
```elixir
# Insert all
users = [
  %{name: "John", email: "john@example.com"},
  %{name: "Jane", email: "jane@example.com"}
]
Repo.insert_all(User, users)

# Update all
from(u in User, where: u.active == false)
|> Repo.update_all(set: [active: true])
```

## 5. Testing Database

### Test Setup
```elixir
# test/support/data_case.ex
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MyApp.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MyApp.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
    end

    :ok
  end
end
```

### Factory Pattern
```elixir
# test/support/factory.ex
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo

  def user_factory do
    %MyApp.Accounts.User{
      name: "John Doe",
      email: sequence(:email, &"user#{&1}@example.com"),
      age: 25,
      active: true
    }
  end
end
```