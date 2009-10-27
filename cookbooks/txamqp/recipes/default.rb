include_recipe "setuptools"

bash "install_txamqp" do
user "root"
  code "easy_install txamqp"
end
