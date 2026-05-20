# PostgreSQL Optimization Skills

## Database Performance

### Indexing Strategies
- Create indexes on frequently queried columns
- Use composite indexes for multi-column queries
- Monitor index usage with pg_stat_user_indexes
- Remove unused indexes to improve write performance

### Query Optimization
- Use EXPLAIN ANALYZE to understand query plans
- Avoid N+1 queries with proper preloading
- Use database functions for complex calculations
- Implement pagination for large result sets

### Connection Management
- Configure connection pooling properly
- Monitor connection usage
- Use read replicas for read-heavy workloads
- Implement connection timeouts

## Ecto Best Practices

### Efficient Queries
```elixir
# Preload associations to avoid N+1
users = Repo.all(from u in User, preload: [:posts, :profile])

# Use select to limit returned fields
users = Repo.all(from u in User, select: [:id, :name, :email])

# Implement cursor-based pagination
def list_users_paginated(cursor \\ nil, limit \\ 20) do
  query = from u in User, order_by: u.id, limit: ^limit
  
  query = if cursor do
    from u in query, where: u.id > ^cursor
  else
    query
  end
  
  Repo.all(query)
end
```

### Batch Operations
```elixir
# Use insert_all for bulk inserts
users = [%{name: "John"}, %{name: "Jane"}]
Repo.insert_all(User, users)

# Use update_all for bulk updates
from(u in User, where: u.active == false)
|> Repo.update_all(set: [active: true])
```

## Monitoring & Maintenance

### Performance Monitoring
- Monitor slow queries
- Track database metrics (CPU, memory, I/O)
- Use pg_stat_statements for query analysis
- Set up alerts for performance degradation

### Database Maintenance
- Regular VACUUM and ANALYZE operations
- Monitor table and index bloat
- Plan for database backups and recovery
- Keep PostgreSQL version updated