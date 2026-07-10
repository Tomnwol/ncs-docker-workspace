# ncs-docker-workspace

Docker-based development workspace for [Nordic nRF Connect SDK](https://www.nordicsemi.com/Products/Development-software/nrf-connect-sdk) (NCS). Build and flash Zephyr applications with `west`, without installing the SDK on your host.

Each NCS version gets its own pre-baked Docker image. Application sources live on the host and are mounted into the container at runtime.

## Features

- **Multi-version** — run NCS v2.9.2 and v3.3.1 side by side, each in its own image
- **SDK baked in** — `west init` + `west update` run at image build time; no download on container start
- **Simple workflow** — `make image-<app>` then `make shell-<app>` from the host; `west` inside the container
- **Flash-ready** — privileged container with USB device access for programming a Nordic DK

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2.20+
- A Nordic development kit connected via USB (for flashing)
- On **WSL2**: expose the DK to Linux with [usbipd-win](https://learn.microsoft.com/en-us/windows/wsl/connect-usb)

## Installation

Clone the repository:

```bash
git clone <repo-url> 
cd ncs-docker-workspace
```

Build the Docker image for your target NCS version (first run downloads the toolchain and SDK — this can take a while):

```bash
make image-hello_world-3-3-1
```

List available targets:

```bash
make help
```

## Getting started

All `make` targets run on the **host**. Inside the container, use `west` directly (there is no `make`).

### 1. Configure your board

Edit the `.env` file in the version folder you are using, for example `v3-3-1/.env`:

```env
NCS_VERSION=v3.3.1
DEFAULT_BOARD=nrf9160dk/nrf9160/ns
```

### 2. Open a development shell

```bash
make shell-hello_world-3-3-1
```

The container starts in `/workspace` (the NCS SDK) and prints ready-to-run commands. These environment variables are exported:

| Variable | Example | Purpose |
|----------|---------|---------|
| `APP_DIR` | `/apps/hello_world` | Application source |
| `BUILD_DIR` | `/apps/hello_world/build` | Build output |
| `DEFAULT_BOARD` | `nrf9160dk/nrf9160/ns` | Board passed to `west build` |

For more informations about the board name, check [nordic documentation](https://nrfconnectdocs.nordicsemi.com/ncs/latest/nrf/app_dev/device_guides/nrf91/index.html).

### 3. Build and flash

Inside the container:

```bash
west build -p always -b $DEFAULT_BOARD -d $BUILD_DIR $APP_DIR
west flash -r nrfutil -d $BUILD_DIR
```

### 4. Read the serial output

On the host (outside the container):

```bash
minicom -D /dev/ttyACM0 -b 115200
```

## Usage

### Make targets

| Target | Description |
|--------|-------------|
| `make help` | List configured projects and available targets |
| `make image-<app>-<version>` | Build the NCS Docker image for this app/version |
| `make shell-<app>-<version>` | Open an interactive shell for this app |

When an app exists in only one NCS version, the short form works:

```bash
make shell-blink_led
make image-blink_led
```

When the same app exists on multiple versions, specify the version suffix:

```bash
make shell-hello_world-3-3-1
make shell-hello_world-2-9-2
```

### Configured projects

Defined in the root `Makefile`:

```makefile
PROJECTS = \
	hello_world:3-3-1 \
	hello_world:2-9-2 \
	blink_led:3-3-1
```

Each entry is `<app>:<version-slug>`. The slug matches the folder name without the leading `v` (`3-3-1` → `v3-3-1/`).

## Project structure

```
ncs-docker-workspace/
├── Makefile                   # Host-side entry point (image, shell)
├── shared/
│   ├── Dockerfile             # Extends Nordic toolchain image, runs west init/update
│   ├── docker-compose.base.yml
│   └── container-shell.sh     # Interactive container entrypoint
├── v3-3-1/                    # NCS v3.3.1
│   ├── .env                   # NCS_VERSION, DEFAULT_BOARD
│   ├── docker-compose.yml
│   └── apps/
│       ├── hello_world/
│       └── blink_led/
└── v2-9-2/                    # NCS v2.9.2
    ├── .env
    ├── docker-compose.yml
    └── apps/
        └── hello_world/
```

## Adding an application

1. **Create the project** under `v<version>/apps/<app_name>/`. Copy an existing app as a starting point:

   ```bash
   cp -r v3-3-1/apps/hello_world v3-3-1/apps/my_sensor
   ```

   A minimal app needs `CMakeLists.txt`, `prj.conf`, and `src/main.c`.

2. **Register it** in the root `Makefile`:

   ```makefile
   PROJECTS = \
   	hello_world:3-3-1 \
   	my_sensor:3-3-1
   ```

3. **Build the image and open a shell**:

   ```bash
   make image-my_sensor-3-3-1
   make shell-my_sensor-3-3-1
   ```

## Adding an NCS version

1. Copy an existing version folder, e.g. `cp -r v3-3-1 v3-4-0`
2. Set `NCS_VERSION` in `v3-4-0/.env`
3. Update the compose project name in `v3-4-0/docker-compose.yml` (`name: nordic-v3-4-0`)
4. Register apps in `PROJECTS` with the new version slug

## Configuration

| Variable | Location | Purpose |
|----------|----------|---------|
| `PROJECTS` | `Makefile` | Apps and their NCS versions (`<app>:<version-slug>`) |
| `NCS_VERSION` | `v<version>/.env` | SDK version — drives toolchain image, built image tag, and west manifest |
| `DEFAULT_BOARD` | `v<version>/.env` | Default board for `west build` |

## How it works

1. `shared/Dockerfile` extends the official [Nordic toolchain image](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/scripts/docker/README.html) and runs `west init` + `west update` at **image build time**.
2. The full NCS SDK is baked into the image at `/workspace`.
3. Application sources are bind-mounted from `v<version>/apps/`.
4. Flashing uses `nrfutil` via a privileged container with `/dev` and udev rules from the host.
