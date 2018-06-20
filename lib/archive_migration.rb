require 'archive_migration/version'
require 'fileutils'
require 'mysql2'
require 'pry'
require 'set'
require 'yaml'

module ArchiveMigration
  extend self

  require :VERSION, 'archive_migration/version'

  def start
    if ask(:have_run_all_migrations)
      archive
    else
      if ask(:run_all_migrations)
        run_all_migrations
        archive
      end
    end
  end

  def archive
    tell(:creating_archive_folder)
    FileUtils::mkdir_p './db/archive'

    tell(:moving_files)
    version_list = archive_by_year

    tell(:generating_migration)
    data = IO.read('./db/schema.rb')
    File.write("./db/migrate/#{version_list.max}_from_previous_version.rb", "class FromPreviousVersion < ActiveRecord::Migration\n\tdef change\n" + data[data.index('do')+3..data.rindex('end')-1] + "\tend\nend\n")

    delete_by_version_list(version_list) if ask(:delete_from_schema_table)
    create_version_list(version_list)
  end

  def create_version_list(version_list)
    version_list_file = File.open("./db/archive/version_list.txt", "a")
    version_list.sort.each do |version|
      line = version + ','
      version_list_file.write(line)
    end
  end

  def delete_by_version_list(version_list)
    dir = './db/archive/version_list.txt'
    if version_list.any?
      deleting_list = version_list.clone
      if File.exist?(dir)
        list = IO.read(dir)
        deleting_list << list.split(/[\s,']/).max
      end
      delete_from_schema_table(deleting_list)
    else
      if File.exist?(dir)
        list = IO.read(dir)
        delete_from_schema_table(list.split(/[\s,']/))
      end
    end
  end

  def archive_by_year
    dir = './db/migrate'
    files = Dir.foreach(dir).select { |x| File.file?("#{dir}/#{x}") && !x.include?("from_previous_version") }
    version_list = []
    files.each do |file|
      version_list << file.split('_').first
    end

    years = get_years(version_list)
    years.each do |year|
      FileUtils::mkdir_p "./db/archive/#{year}"
    end

    Dir.glob('./db/migrate/*.rb').each do |file|
      file_version = file.split('/').last.split('_').first
      if file.split('/').last.include?("from_previous_version")
        FileUtils.rm file
      else
        FileUtils.mv file, "./db/archive/#{file_version[0..3]}"
      end
    end

    return version_list
  end

  def recover
    dir = './db/archive/version_list.txt'
    if File.exist?(dir)
      list = IO.read(dir)
      insert_into_schema_table(list.split(/[\s,']/))
    end
  end

  def tell(key, options = {})
    message = messages.fetch(key.to_s)
    message = colorize(message)
    print(message, options)
  end

  def run_all_migrations
    tell(:running_migrations)
    system('bundle exec rake db:migrate')
  end

  private

  COLORS = ['red', 'green', 'yellow', 'blue'].each_with_index.inject({}) { |r, (k, i)| r.merge!(k => "03#{ i + 1 }") }

  def get_default_database
    dir = './config/sample_database.yml'
    dir2 = './config/database.yml'
    if File.exist?(dir)
      database_hash = YAML.load_file(dir)
    elsif File.exist?(dir2)
      database_hash = YAML.load_file(dir2)
    end
    return database_hash ? database_hash["development"] : nil
  end

  def insert_into_schema_table(inserting_list)
    begin
      tell(:connecting_mysql)
      client = Mysql2::Client.new(:host => "127.0.0.1", :username => "root")
      databases = get_databases(client)
      default_database = get_default_database
      if default_database.any? && databases.include?(default_database["database"])
        print("Default Database: " + default_database["database"])
        if ask(:connecting_database)
          client.select_db(default_database["database"])
        else
          selection = ask_selection(:selection, databases).strip
          client.select_db(selection)
        end
      else
        selection = ask_selection(:selection, databases).strip
        client.select_db(selection)
      end
      inserting_list.each do |version|
        if !version.nil? && version != inserting_list.max
          client.query("INSERT INTO schema_migrations(version) VALUES (#{version})")
        end
      end

    rescue Mysql2::Error => e
      puts e.errno
      puts e.error
    ensure
      client.close if client
    end
  end

  def delete_from_schema_table(deleting_list)
    begin
      tell(:connecting_mysql)
      client = Mysql2::Client.new(:host => "127.0.0.1", :username => "root")
      databases = get_databases(client)
      default_database = get_default_database
      if default_database.any? && databases.include?(default_database["database"])
        print("Default Database: " + default_database["database"])
        if ask(:connecting_database)
          client.select_db(default_database["database"])
        else
          selection = ask_selection(:selection, databases).strip
          client.select_db(selection)
        end
      else
        selection = ask_selection(:selection, databases).strip
        client.select_db(selection)
      end
      tell(:cleaning)
      rs = client.query("SELECT version FROM schema_migrations")
      exist_versions = rs.map { |v| v['version'] }
      deleting_list.each do |version|
        if exist_versions.include?(version) && !version.nil? && version != deleting_list.max
          client.query("DELETE FROM schema_migrations where version = #{version}")
        end
      end

    rescue Mysql2::Error => e
      puts e.errno
      puts e.error
    ensure
      client.close if client
    end
  end

  def get_years(version_list)
    years = Set.new
    version_list.each do |version|
      years << version[0..3]
    end
    return years
  end

  def get_databases(conn)
    rows = []
    rs = conn.query("show databases")
    rs.each do |x|
      rows<<x["Database"] if !x.nil?
    end

    return rows
  end

  def print(message, options = {})
    if options.empty?
      puts message % options
    else
      puts message
      puts options
    end
    puts ''
  end

  def ask(*args)
    tell(*args)
    $stdin.gets[0].downcase == 'y'
  end

  def ask_selection(*args, databases)
    tell(*args, databases)
    selection = $stdin.gets
    while !databases.include?(selection.strip)
      tell(:wrong_inputs)
      tell(*args, databases)
      selection = $stdin.gets
    end

    return selection.strip
  end

  def messages
    require 'yaml'
    path = File.join(File.dirname(__FILE__), 'archive_migration/messages.yml')
    @messages = YAML.load(File.open(path))
  end

  def colorize(message)
    message.gsub(/\:(\w+)\<([^>]+)\>/) { |_| "\033[#{ COLORS[$1] }m#{ $2 }\033[039m" }
  end
end
