import os
import subprocess


def setup_ssh():
    email = input("Please enter your email: ")

    ssh_dir = os.path.expanduser("~/.ssh")

    id_name = input("Enter a custom identifier for the SSH key: ").strip()
    if not id_name:
        print("No identifier provided. Aborting SSH setup.")
        return

    private_key_path = os.path.join(ssh_dir, f"{id_name}_ed25519")
    public_key_path = private_key_path + ".pub"
    ssh_config_path = os.path.join(ssh_dir, "config")

    if not os.path.exists(ssh_dir):
        os.makedirs(ssh_dir)

    try:
        print("Generating SSH key pair...")
        subprocess.run(
            [
                "ssh-keygen",
                "-t",
                "ed25519",
                "-f",
                private_key_path,
                "-C",
                email,
                "-N",
                "",
            ],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print("Error generating SSH key pair:")
        print(e)

    try:
        with open(public_key_path, "r") as file:
            print("\nPublic key:")
            print(file.read())
    except FileNotFoundError:
        print(f"Public key file not found: {public_key_path}")

    print("\nPlease copy and paste the public key to Bitbucket/Github.")

    try:
        print("Starting ssh-agent and adding private key...")
        command = 'eval "$(ssh-agent -s)" && ssh-add ' + private_key_path
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print("Error starting ssh-agent or adding private key:")
        print(e)

    try:
        print("Adding host to ssh config...")
        with open(ssh_config_path, "a") as file:
            file.write(f"\nHost github.com\n")
            file.write(f"  AddKeysToAgent yes\n")
            file.write(f"  IdentityFile {private_key_path}\n")
    except IOError as e:
        print("Error writing to ssh config file:")
        print(e)


def main():
    setup_ssh_prompt = input("Do you want to setup ssh? (y/N): ")
    if not setup_ssh_prompt:
        setup_ssh_prompt = "n"
    if setup_ssh_prompt.lower() in ["y", "yes"]:
        setup_ssh()
        key_copied_prompt = input(
            "Have you already copied and pasted the public key to Bitbucket/Github? (y/N): "
        )
        if not key_copied_prompt:
            key_copied_prompt = "n"
        if key_copied_prompt.lower() not in ["y", "yes"]:
            print(
                "Please copy and paste the public key to Bitbucket/Github before proceeding."
            )
            return

    continue_setup_prompt = input("Do you want to continue with the setup? (y/N): ")
    if not continue_setup_prompt:
        continue_setup_prompt = "n"
    if continue_setup_prompt.lower() not in ["y", "yes"]:
        print("Setup aborted.")
        return


if __name__ == "__main__":
    main()
