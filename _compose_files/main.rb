compose do |c, _run|
  c.service :app do |s|
    s.port_conf app_port: 80
    s.source_code :app
  end
end
