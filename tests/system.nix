{ pkgs, ... }:

{
  name = "system-config-test";

  nodes = {
    machine = { config, pkgs, ... }: {
      # Minimal system config for testing
      boot.loader.systemd-boot.enable = true;
      networking.hostName = "test-machine";
      system.stateVersion = "24.05";

      # Test services
      systemd.services.docker.enable = true;
      systemd.services.NetworkManager.enable = true;

      # Test packages
      environment.systemPackages = with pkgs; [
        fish
        neovim
        git
        ansible
        curl
        wget
      ];

      # Test user
      users.users.testuser = {
        isNormalUser = true;
        extraGroups = [ "wheel" "docker" "video" ];
        shell = pkgs.fish;
      };
    };
  };

  testScript = ''
    # Wait for system to boot
    machine.wait_for_unit("multi-user.target")

    # Test services are running
    machine.systemctl("is-active NetworkManager")

    # Test packages are installed
    machine.succeed("fish --version")
    machine.succeed("nvim --version")
    machine.succeed("git --version")
    machine.succeed("ansible --version")
    machine.succeed("curl --version")

    # Test user exists with correct groups
    machine.succeed("id testuser")
    machine.succeed("groups testuser | grep docker")
    machine.succeed("groups testuser | grep video")

    # Test directories exist
    machine.succeed("test -d /home/testuser")

    # Test shell is fish
    machine.succeed("getent passwd testuser | grep fish")

    print("✓ All system tests passed!")
  '';
}
