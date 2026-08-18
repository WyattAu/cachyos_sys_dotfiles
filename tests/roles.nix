{ pkgs, ... }:

{
  name = "ansible-role-test";

  nodes = {
    # Test machine for package installation role
    package_test = { config, pkgs, ... }: {
      boot.loader.systemd-boot.enable = true;
      system.stateVersion = "24.05";

      environment.systemPackages = with pkgs; [
        fish
        neovim
        git
        curl
        wget
        bat
        eza
        fzf
        zoxide
        ripgrep
        btop
        fastfetch
      ];
    };

    # Test machine for service enablement role
    service_test = { config, pkgs, ... }: {
      boot.loader.systemd-boot.enable = true;
      system.stateVersion = "24.05";

      systemd.services.test-service = {
        description = "Test service";
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        serviceConfig.RemainAfterExit = true;
        serviceConfig.ExecStart = "${pkgs.coreutils}/bin/true";
      };

      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 80 443 ];
    };

    # Test machine for security hardening role
    security_test = { config, pkgs, ... }: {
      boot.loader.systemd-boot.enable = true;
      system.stateVersion = "24.05";

      security.sudo.wheelNeedsPassword = true;

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    };
  };

  testScript = ''
    # Package installation tests
    package_test.wait_for_unit("multi-user.target")
    package_test.succeed("fish --version")
    package_test.succeed("nvim --version")
    package_test.succeed("bat --version")
    package_test.succeed("eza --version")
    package_test.succeed("fzf --version")
    package_test.succeed("zoxide --version")
    package_test.succeed("rg --version")
    package_test.succeed("btop --version")
    print("✓ Package installation tests passed!")

    # Service enablement tests
    service_test.wait_for_unit("multi-user.target")
    service_test.succeed("systemctl is-active test-service")
    service_test.succeed("systemctl is-active firewall")
    print("✓ Service enablement tests passed!")

    # Security hardening tests
    security_test.wait_for_unit("multi-user.target")
    security_test.succeed("systemctl is-active sshd")
    security_test.succeed("grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config")
    security_test.succeed("grep -q 'PermitRootLogin no' /etc/ssh/sshd_config")
    print("✓ Security hardening tests passed!")

    print("✓ All role tests passed!")
  '';
}
