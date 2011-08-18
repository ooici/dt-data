interface = node[:dhcphostname][:interface]
hostname = node[:dhcphostname][:hostname]

if hostname and !hostname.empty?

  case node[:platform]
    when "redhat", "centos", "fedora"

      # simply append DHCP_HOSTNAME line -- it is sourced, so duplicates are
      # washed out.

      execute "Set DHCP hostname" do
        command "echo 'DHCP_HOSTNAME=#{hostname}' >> /etc/sysconfig/network-scripts/ifcfg-#{interface}"
      end

      execute "Reset #{interface}" do
        command "ifdown #{interface} && ifup #{interface}"
      end
  end
end
