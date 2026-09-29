# Pop!_OS Setup Scripts

Scripts for setting up and reproducing my Pop!_OS development environment.

The goal of this repository is to make it possible to rebuild my laptop after a fresh Pop!_OS installation without having to manually remember every system configuration and package that needs to be installed.

## Purpose

This repository contains scripts that automate the setup of my Pop!_OS base system.

The scripts are intended to:

* Install required system packages and development tools
* Configure commonly used system settings
* Set up the environment needed for software development
* Reduce the amount of manual work required after reinstalling Pop!_OS
* Provide a repeatable way to reproduce the system configuration

The scripts are **not intended to create a complete backup of the machine**.

## Scope

This repository focuses on the **base operating system and development environment**.

Things that are intentionally outside the scope of the setup scripts include:

* Personal files
* User-specific documents
* Game installations
* Steam libraries
* Projects and source code
* Application data that changes frequently
* Credentials, passwords, SSH private keys, API keys, and other secrets
* Hardware-specific data that should not be committed to a public repository

Applications or tools that change frequently can be installed separately when needed rather than being treated as part of the base system.

## Usage

### 1. Install Pop!_OS

Start with a fresh installation of Pop!_OS.

Complete the initial setup and make sure the system has an active internet connection.

### 2. Clone this repository

Clone the repository onto the newly installed system:

```bash
git clone <repository-url>
cd popos-setup
```

Replace `<repository-url>` with the URL of this repository.

### 3. Review the scripts

Before running anything, review the scripts to understand what changes they will make to the system.

Do not blindly execute setup scripts obtained from an untrusted source.

### 4. Run the setup

Run the appropriate setup script:

```bash
chmod +x <setup-script>
./<setup-script>
```

Some operations may require administrator privileges. The script will request `sudo` access when necessary.

### 5. Reboot if required

Some system changes may not take effect until after restarting the computer.

```bash
sudo reboot
```

## Reproducibility

The primary reason for this repository is recovery and reproducibility.

If the laptop needs to be reinstalled, the intended process is:

1. Install Pop!_OS.
2. Clone this repository.
3. Run the setup scripts.
4. Restore personal files and projects separately.
5. Reinstall any software that has intentionally been kept outside the base setup.

This means the repository acts as a **rebuild procedure**, rather than a full system image.

## Design Principles

### Keep the base setup stable

Only software and configuration that are considered part of the normal development environment should be included.

### Avoid unnecessary automation

Not every application needs to be installed automatically.

If something is frequently changed, experimental, or dependent on a particular project, it is generally better handled separately.

### Keep secrets out of the repository

No passwords, authentication tokens, private keys, or other secrets should be stored in these scripts.

### Prefer reproducibility over cloning every detail

The objective is not to reproduce every byte of the original installation.

The objective is to reproduce a functional development machine with minimal manual setup.

## Firmware Updates

Firmware-update checking is intentionally left outside the setup script.

Firmware can be checked manually when appropriate using the system's firmware-management tools.

## Games

Game installation is intentionally excluded from these scripts.

Game libraries and installed games can change independently of the base development environment, so they are not considered part of the reproducible Pop!_OS setup.

## Updating the Scripts

As the system is used over time, missing setup steps can be added to the scripts when they become apparent.

Before adding something, consider whether it belongs in the reproducible base environment or whether it is better handled separately.

The goal is to keep the scripts useful without turning them into an attempt to automate every aspect of the machine.

## Recovery Workflow

In the event that the laptop needs to be rebuilt:

```text
Fresh Pop!_OS installation
        │
        ▼
Clone this repository
        │
        ▼
Run setup scripts
        │
        ▼
Restore personal files/projects
        │
        ▼
Install optional or changing software
        │
        ▼
Ready for development
```

## Repository Structure

The repository structure may evolve as the setup process is refined.

For example:

```text
popos-setup/
├── README.md
├── LICENSE
└── <setup scripts>
```

The scripts themselves are the source of truth for the automated setup process.

## Notes

This repository reflects my own Pop!_OS setup and hardware requirements. It should not be assumed to be a universal Pop!_OS configuration.

Review and adapt the scripts before using them on another machine.

## License

See [LICENSE](LICENSE) for the license under which this repository is distributed.
