RSpec.describe ArchiveMigration do
  it "has a version number" do
    expect(ArchiveMigration::VERSION).not_to be nil
  end

  it "testing" do
    ArchiveMigration.recover
  end
end
