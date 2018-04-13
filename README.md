# ArchiveMigration

Archive ruby migration files.

## Installation

Run
```
$ gem install archive_migration
```
## Usage

Run the following command to execute archive:
```
archive_migration
```

The ArchiveMigration takes following steps:
- create new folder `/archive`, move all up to date migrations to this folder by year
- create new file with latest migration version number and all code in `schema.rb`
- delete old version numbers in schema_migrations table to avoid `rake db:migrate:status` have `***NO FILE***` output.

This gem also supports following options:
```
Supported options:
    -y                               already run all migrations
    -m, --migrate                    run migrations and then archive
    -d, --delete                     delete version list from schema_migrations table
    -r, --recover                    redo all archive actions (in progress)
    -z, --zip                        zip archive folder (next version)
    -p, --push                       push archive folder to S3 (next version)
    -v, --version                    show gem version
    -h, --help                       show this message
```

## Next step

- add logic to redo all archive actions
- add logic to zip archive folder
- allow user to push archived zip/folder to S3

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/NathanShi/archive_migration. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ArchiveMigration project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/archive_migration/blob/master/CODE_OF_CONDUCT.md).
