require 'open3'
require 'rainbow'

module Tasks
  module Docker
    def docker_compose_file_path
      File.join(APP_ROOT, "docker/docker-compose.#{ENV['environment']}.yml")
    end

    def docker_compose_config
      YAML.load_file(docker_compose_file_path)
    end

    def wait_for_solr_cores_to_load
      expected_port = docker_compose_config['services']['solr']['ports'][0].split(':')[0]
      url_to_check = "http://localhost:#{expected_port}/solr/cul_hydra/admin/system"
      puts "Waiting for Solr to become available (at #{url_to_check})..."
      Timeout.timeout(20, Timeout::Error, 'Timed out during Solr startup check.') do
        loop do
          begin
            sleep 0.25
            status_code = Net::HTTP.get_response(URI(url_to_check)).code
            if status_code == '200' # Solr is ready to receive requests
              puts 'Solr is available.'
              break
            end
          rescue EOFError, Errno::ECONNRESET => e
            # Try again in response to the above error types
            next
          end
        end
      end
    end

    def wait_for_fedora_to_load
      expected_port = docker_compose_config['services']['fedora']['ports'][0].split(':')[0]
      url_to_check = "http://localhost:#{expected_port}/fedora/describe"
      puts "Waiting for Fedora to become available (at #{url_to_check})..."
      Timeout.timeout(20, Timeout::Error, 'Timed out during Fedora startup check.') do
        loop do
          begin
            sleep 0.25
            status_code = Net::HTTP.get_response(URI(url_to_check)).code
            if status_code == '401' # Fedora is ready and prompting for authentication
              puts 'Fedora is available.'
              break
            end
          rescue EOFError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
            # Try again in response to the above error types
            next
          end
        end
      end
    end

    def running?
      status = `docker compose -f #{File.join(APP_ROOT, docker_compose_file_path)} ps`
      status.split("n").count > 1
    end

    def docker_wrapper(start_task: 'cul_hydra:docker:start', stop_task: 'cul_hydra:docker:stop', delete_volumes_task: 'cul_hydra:docker:delete_volumes', &block)
      unless ENV['environment'].to_s == 'test'
        raise 'This task should only be run in the test environment (because it clears docker volumes)'
      end

      # Stop docker if it's currently running (so we can delete any old volumes)
      Rake::Task[stop_task].invoke
      # Rake tasks must be re-enabled if you want to call them again later during the same run
      Rake::Task[stop_task].reenable

      ENV['rails_env_confirmation'] = ENV['environment'].to_s # setting this to skip prompt in volume deletion task
      Rake::Task[delete_volumes_task].invoke

      Rake::Task[start_task].invoke
      begin
        block.call
      ensure
        Rake::Task[stop_task].invoke
      end
    end
  end
end