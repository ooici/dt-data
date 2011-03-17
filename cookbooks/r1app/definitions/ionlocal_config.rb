define :ionlocal_config, :user => nil, :group => nil, :universals => {}, 
    :locals => {} do
  
  raise ArgumentError, 'user must be specified' if :user.nil?
  raise ArgumentError, 'group must be specified' if :group.nil?

  # The following excruciating ionlocal.config work should be a Ruby block
  bash "create ionlocal.config" do
    user "#{params[:user]}"
    group "#{params[:group]}"
    code <<-EOH
    echo -e "{\n'epu.universal':{" > #{params[:name]}
    chmod 600 #{params[:name]}
    EOH
  end
  params[:universals].each do |u_key, u_value|
    bash "add universals to ionlocal.config" do
      user "#{params[:user]}" 
      group "#{params[:group]}"
      code <<-EOH
      echo "    '#{u_key}': '#{u_value}'," >> #{params[:name]}
      EOH
    end
  end
  bash "modify ionlocal.config" do
    user "#{params[:user]}"
    group "#{params[:group]}"
    code <<-EOH
    echo "}," >> #{params[:name]}
    EOH
  end
  # Brutal:
  params[:locals].each do |section_name, keyvalue_dict|
    bash "add local section to ionlocal.config" do
      user "#{params[:user]}" 
      group "#{params[:group]}"
      code <<-EOH
      echo "'#{section_name}':{" >> #{params[:name]}
      EOH
    end
    keyvalue_dict.each do |l_key, l_value|
      ruby_block "build-line" do
        block do
          config_line = "     '#{l_key}': '" + l_value.to_s + "',\n"
          File.open(params[:name], 'a') {|f| f.write(config_line) }
        end
      end
    end
    bash "finish local section to ionlocal.config" do
      user "#{params[:user]}" 
      group "#{params[:group]}"
      code <<-EOH
      echo "}," >> #{params[:name]}
      EOH
    end
  end
  bash "finish ionlocal.config" do
    user "#{params[:user]}" 
    group "#{params[:group]}"
    code <<-EOH
    echo "}" >> #{params[:name]}
    EOH
  end
end
