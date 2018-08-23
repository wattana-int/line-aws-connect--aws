compose do |c, run|
  stack_name = "line-connect--#{run.group}"

  c.service :app do |s|
    s.environments STACK_NAME: stack_name
    s.environment_vars :NODE_ENV, :SAM, :AWS, :LINE
    s.source_code :app

    s.named_volume app_node_modules: '/app/node_modules'

    root_lambda_funcs = c.project_path.join 'app/lambda'
    dirs = Dir.glob(root_lambda_funcs.join('*'))
              .map { |e| Pathname.new e }
              .select(&:directory?)
              .select { |e| e.join('package.json').file? }
              .map(&:basename)
              .map(&:to_s)
              .sort

    dirs.each do |name|
      s.named_volume("lambda_#{name}_node_modules" => "/app/lambda/#{name}/node_modules")
    end

    s.vars.each do |k, v|
      next unless k.start_with? 'AWS_SAM_LOCAL_PORT_'
      s.ports ["#{v}:#{v}"]
    end
    
    if run.conf :docker_socket
      s.volumes '/var/run/docker.sock' => run.conf(:docker_socket)
    elsif run.conf :docker_daemon_port
      s.environments DOCKER_HOST: run.conf(:docker_daemon_port)
    end
  end
end
