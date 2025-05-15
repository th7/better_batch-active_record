# BetterBatch::ActiveRecord

BetterBatch::ActiveRecord allows you to upsert to your database and get an ID back for every row of input data regardless of whether the row was inserted, updated, or unchanged. ActiveRecord's existing upsert methods do not do this.

Always getting an ID makes it much easier to correctly associate records during bulk imports.

For now, only Postgres is supported.

## Installation

In your Gemfile:
```ruby
source 'https://rubygems.org'
gem 'better_batch-active_record'
```
Then:
`bundle`

## Usage

```ruby
class MyModel < ApplicationModel
  extend BetterBatch::ActiveRecord::Model
end

# all rows must have the same keys
data = [
  { unique_field: 1, ... },
  { unique_field: 2, ... },
  { unique_field: 3, ... },
  ...
]

# you can have the library mutate your input data directly
MyModel.better_batch.set_upserted_pk(data, unique_by: :unique_field)
=> nil
data
=> [ { id: 1, unique_field: ... }, ...]

# if you need to do something a little more involved
# except: will prevent extraneous fields from going to the database
MyModel.better_batch.with_upserted_pk(data, except: :child_records, unique_by: :unique_field) do |data, pk|
  data[:id] = id
  data[:child_records].each do |child_record|
    child_record[:parent_id] = id
  end
end

# you can return fields that you did not modify
MyModel.better_batch.upsert(data, unique_by: :unique_field, returning: [:id, :unmodified_field])
=> [{ id: 1, unmodified_field: 'unmodified data' }, ...]

# you can return all fields
MyModel.better_batch.upsert(data, unique_by: :unique_field, returning: '*')
=> [{ id: 1, unmodified_field: 'unmodified data', another_field: ... }, ...]

# you can use select/selected variations if you don't want any inserts/updates
# missing rows will have a nil primary key
MyModel.better_batch.set_selected_pk(data, unique_by: :unique_field)
=> nil
data
=> [ { id: 1, unique_field: ... }, ...]

MyModel.better_batch.with_selected_pk(data, unique_by: :unique_field) do |data, pk|
  # can be used similarly to the upsert example above
end

# maybe you don't need any results at all
MyModel.better_batch.upsert(data, unique_by: :unique_field)
=> nil

# or maybe something as simple as this is useful to you
MyModel.better_batch.upsert(data, unique_by: :unique_field, returning: :id)
=> [1, 2, 3, ...]
```

## Possible Future Usage

```ruby
# you can get back instantiated models with all fields
# including the primary key
MyModel.better_batch.upsert(data, unique_by: :unique_field, return_type: :model)
=> [*models]

MyModel.better_batch.select(data, unique_by: :unique_field, return_type: :model)
=> [*models]

# you can similarly get models with only some populated fields
MyModel.better_batch.upsert(data, unique_by: :unique_field, return_type: :model, returning: [:id, :field1])
=> [*models_with_only_id_and_field1_populated]

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/th7/better_batch-active_record. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/th7/better_batch-active_record/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BetterBatch project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/th7/better_batch-active_record/blob/master/CODE_OF_CONDUCT.md).
