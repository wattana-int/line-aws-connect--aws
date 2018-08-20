compose do |c, _run|
  c.service :app do |s|
    s.restart :always
  end
end
