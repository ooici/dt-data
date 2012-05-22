case node[:platform]
when "ubuntu","debian"
  %w{ python python-dev }.each do |pkg|
    package pkg
  end
end
