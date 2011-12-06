require 'yaml'
define :epuservice_config, :user => nil, :group => nil, :epuservice_name => nil, :epuservice_spec => nil do
  
  raise ArgumentError, 'user must be specified' if params[:user].nil?
  raise ArgumentError, 'group must be specified' if params[:group].nil?
  raise ArgumentError, 'epuservice_name must be specified' if params[:epuservice_name].nil?
  raise ArgumentError, 'epuservice_spec must be specified' if params[:epuservice_spec].nil?
 
  cfg_file = params[:name]
  cfg_yaml = YAML.dump params[:epuservice_spec].first['config']
  cfg_yaml.gsub!(/!\S*/, '') # Strip ruby-specific tags
  
  file cfg_file do
    owner params[:user]
    group params[:group]
    content cfg_yaml
  end
end
