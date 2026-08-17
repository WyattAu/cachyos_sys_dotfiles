{ pkgs, ... }:

{
  name = "ansible-role-test";

  nodes = {
    # Test machine for package installation role
    package-test = { config, pkgs, ... }: {
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
    service-test = { config, pkgs, ... }: {
      boot.loader.systemd-boot.enable = true;
      system.stateVersion = "24.05";

      systemd.services.test-service = {
        description = "Test service";
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.coreutils}/bin/true";
      };

      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 80 443 ];
    };

    # Test machine for security hardening role
    security-test = { config, pkgs, ... }: {
      boot.loader.systemd-boot.enable = true;
      system.stateVersion = "24.05";

      security.sudo.wheelNeedsPassword = true;
      security.pam.services.login.failDelay = 4000;

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
    package-test.wait_for_unit("multi-user.target")
    package-test.succeed("fish --version")
    package-test.succeed("nvim --version")
    package-test.succeed("bat --version")
    package-test.succeed("eza --version")
    package-test.succeed("fzf --version")
    package-test.succeed("zoxide --version")
    package-test.succeed("rg --version")
    package-test.succeed("btop --version")
    print("✓ Package installation tests passed!")

    # Service enablement tests
    service-test.wait_for_unit("multi-user.target")
    service-test.succeed("systemctl is-active test-service")
    service-test.succeed("systemctl is-active firewalld")
    service-test.succeed("ss -tlnp | grep ':22'")
    service-test.succeed("ss -tlnp | grep ':80'")
    service-test.succeed("ss -tlnp | grep ':443'")
    print("✓ Service enablement tests passed!")

    # Security hardening tests
    security-test.wait_for_unit("multi-user.target")
    security-test.succeed("systemctl is-active sshd")
    security-test.succeed("grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config")
    security-test.succeed("grep -q 'PermitRootLogin no' /etc/ssh/sshd_config")
    print("✓ Security hardening tests passed!")

    print("✓ All role tests passed!")
  '';
}
