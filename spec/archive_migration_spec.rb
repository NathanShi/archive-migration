RSpec.describe ArchiveMigration do
  it "has a version number" do
    expect(ArchiveMigration::VERSION).not_to be nil
  end

  it "run archive function" do
    ArchiveMigration.archive
    ArchiveMigration.delete_from_schema_table
  end
end
