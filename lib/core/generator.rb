require 'fileutils'

class ProjectGenerator
  def initialize(name)
    @name = name
    @gem_path = get_gem_path
  end

  def generate
    make_project_folder
    make_cert_folder
    copy_conf_folder
    copy_requests_folder
  end

  private

  def get_gem_path
    path = `gem which nfe`
    File.dirname(path)
  end

  def make_project_folder
    Dir.mkdir(@name) unless Dir.exists(@name)
  end

  def make_cert_folder
    cert_folder = File.join(@name, 'cert')
    Dir.mkdir(cert_folder)
  end

  def copy_conf_folder
    conf_path = File.join(@gem_path, 'configuration/conf')
    FileUtils.cp_r conf_path @name
  end

  def copy_requests_folder
    conf_path = File.join(@gem_path, 'configuration/requests')
    FileUtils.cp_r conf_path @name
  end
end
