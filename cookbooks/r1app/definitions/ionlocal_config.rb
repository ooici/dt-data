define :ionlocal_config, :user => nil, :group => nil, :universals => {}, 
    :locals => {} do
  
  raise ArgumentError, 'user must be specified' if params[:user].nil?
  raise ArgumentError, 'group must be specified' if params[:group].nil?
  cfg = {'epu.universal' => params[:universals].to_hash}
  params[:locals].each do |section_name, keyvalue_dict|
    cfg[section_name] = keyvalue_dict.to_hash
  end

  cfgfile = params[:name]
  python_datafile cfgfile do
    data cfg
  end
end
