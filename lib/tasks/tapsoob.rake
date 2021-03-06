namespace :tapsoob do
  desc "Pulls a database to your filesystem"
  task :pull => :environment do
    # Default options
    opts={:default_chunksize => 1000, :debug => false, :resume_filename => nil, :disable_compression => false, :indexes_first => false}

    # Get the dump_path
    dump_path = File.expand_path(Rails.root.join("db", Time.now.strftime("%Y%m%d%I%M%S%p"))).to_s

    # Create paths
    FileUtils.mkpath "#{dump_path}/schemas"
    FileUtils.mkpath "#{dump_path}/data"
    FileUtils.mkpath "#{dump_path}/indexes"

    # Run operation
    Tapsoob::Operation.factory(:pull, database_uri, dump_path, opts).run
  end

  desc "Push a compatible dump on your filesystem to a database"
  task :push => :environment do
    # Default options
    opts={:default_chunksize => 1000, :debug => false, :resume_filename => nil, :disable_compression => false, :indexes_first => false}

    # Get the dump_path
    dump_path = Dir[Rails.root.join("db", "*/")].select { |e| e =~ /([0-9]{14})([A-Z]{2})/ }.sort.last

    # Run operation
    Tapsoob::Operation.factory(:push, database_uri, dump_path, opts).run
  end

  private
    def database_uri
      uri               = ""
      connection_config = YAML.load_file(Rails.root.join("config", "database.yml"))[Rails.env]

      case connection_config['adapter']
      when "mysql", "mysql2"
        uri = "#{connection_config['adapter']}://#{connection_config['host']}/#{connection_config['database']}?user=#{connection_config['username']}&password=#{connection_config['password']}"
      when "postgresql", "postgres", "pg"
        uri = "://#{connection_config['host']}/#{connection_config['database']}?user=#{connection_config['username']}&password=#{connection_config['password']}"
        uri = ((RUBY_PLATFORM =~ /java/).nil? ? "postgres" : "postgresql") + uri
      when "oracle_enhanced"
        if (RUBY_PLATFORM =~ /java/).nil?
          uri = "oracle://#{connection_config['host']}/#{connection_config['database']}?user=#{connection_config['username']}&password=#{connection_config['password']}"
        else
          uri = "oracle:thin:#{connection_config['username']}/#{connection_config['password']}@#{connection_config['host']}:1521:#{connection_config['database']}"
        end
      when "sqlite3", "sqlite"
        uri = "sqlite://#{connection_config['database']}"
      else
        raise Exception, "Unsupported database adapter."
        #uri = "#{connection_config['adapter']}://#{connection_config['host']}/#{connection_config['database']}?user=#{connection_config['username']}&password=#{connection_config['password']}"
      end

      uri = "jdbc:#{uri}" unless (RUBY_PLATFORM =~ /java/).nil?

      uri
    end
end
