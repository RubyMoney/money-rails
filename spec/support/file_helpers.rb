require "fileutils"
require "stringio"
require "zlib"

# Helper methods to easily find and manipulate test files.
module FileHelpers
  def gem_path(name, version)
    gems_dir = File.expand_path("../../data/gems", __FILE__)
    gem_dir = File.join(gems_dir, name)
    File.join(gem_dir, "pkg/#{name}-#{version}.gem")
  end

  def read_gem(name, version)
    File.open(gem_path(name, version), "rb", &:read)
  end

  def env_path(name)
    envs_dir = File.expand_path("../../data/environments", __FILE__)
    File.join(envs_dir, name)
  end

  def clean_env(name)
    dir = env_path(name)
    expect(execute("git", ["clean", "-fdx", dir])).to exit_success
  end

  def bundle_path(name)
    bundles_dir = File.expand_path("../../data/bundles", __FILE__)
    File.join(bundles_dir, name)
  end

  def clean_bundle(name)
    dir = bundle_path(name)
    lock_file = File.join(dir, "Gemfile.lock")
    File.delete lock_file if File.exist?(lock_file)
    installed_dir = File.join(dir, "installed_gems")
    FileUtils.remove_entry installed_dir if Dir.exist?(installed_dir)
  end

  def gzip(content)
    begin
      output = StringIO.new
      gz = Zlib::GzipWriter.new(output)
      gz.write(content)
    ensure
      gz.close if gz
    end

    output.string
  end

  def gunzip(content)
    gz = Zlib::GzipReader.new(StringIO.new(content))
    return gz.read
  ensure
    gz.close if gz
  end
end
