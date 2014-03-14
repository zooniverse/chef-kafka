unless ::File.exist?("#{node['kafka']['install_directory']}/#{kafka_name}")
  execute 'install and build kafka' do
    cwd Chef::Config[:file_cache_path]
    command """
      tar -zxf #{kafka_name}-src.tgz && \
      mv #{kafka_name}-src/ #{node['kafka']['install_directory']}/#{kafka_name} && \
      cd #{node['kafka']['install_directory']}/#{kafka_name} && \
      ./sbt update && \
      ./sbt package && \
      ./sbt assembly-package-dependency && \
      chown -R #{node['kafka']['user']}:#{node['kafka']['group']} .
    """
  end
end
