define :ioncontainer_config, :user => nil, :group => nil, :ioncontainer_name => nil, :ioncontainer_spec => nil do
  
  raise ArgumentError, 'user must be specified' if params[:user].nil?
  raise ArgumentError, 'group must be specified' if params[:group].nil?
  raise ArgumentError, 'ioncontainer_name must be specified' if params[:ioncontainer_name].nil?
  raise ArgumentError, 'ioncontainer_spec must be specified' if params[:ioncontainer_spec].nil?
  
  rel = {"type"=>"release", "name"=>params[:ioncontainer_name], "version"=>"0.2", 
    "apps" => params[:ioncontainer_spec]}

  relfile = params[:name]
  python_datafile relfile do
    data rel
  end
end
