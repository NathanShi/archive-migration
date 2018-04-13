require 'archive_migration/version'
require 'fileutils'
require 'mysql2'
require 'pry'

module ArchiveMigration
  extend self

  def archive
    FileUtils::mkdir_p './db/archive'
    dir = './db/migrate'
    files = Dir.foreach(dir).select { |x| File.file?("#{dir}/#{x}") }

    FileUtils.mv Dir.glob('./db/migrate/*.rb'), './db/archive/'
    version_list = []

    files.each do |file|
      version_list << file.split('_').first
    end

    version_list_file = File.open("./db/archive/version_list.txt", "w")
    version_list.sort.each do |version|
      version_list_file.write("(" + "\'" + version+ "\'" + ")" + ',') if version != version_list.max
    end

    data = IO.read('./db/schema.rb')

    File.write("./db/migrate/#{version_list.max}_from_previous_version.rb", "class FromPreviousVersion < ActiveRecord::Migration\n def change\n" + data[data.index('do')+3..data.rindex('end')-1] + " end\nend\n")

    return version_list.max
  end

  def delete_from_schema_table(max_version)
    begin
      client = Mysql2::Client.new(:host => "127.0.0.1", :username => "root", :database => "snapsheet_development")
      rs = client.query("DELETE FROM schema_migrations where version <> #{max_version}")
    rescue Mysql2::Error => e
      puts e.errno
      puts e.error
    ensure
      client.close if client
    end

    system('bundle exec rake db:test:prepare')
  end

  private

  COLORS = ['red', 'green', 'yellow', 'blue'].each_with_index.inject({}) { |r, (k, i)| r.merge!(k => "03#{ i + 1 }") }
end
