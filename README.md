# WWDC BINGO

Play bingo along with wwdc.

## Server code for [wwdcbingo.com](https://wwdcbingo.com)

## Installation

This is a Swift on Server project using [Vapor 4](https://docs.vapor.codes).
It can be run from the included `docker-compose` file on any OS supported by Swift. See  [Vapor on Swift Package Index](https://swiftpackageindex.com/vapor/vapor) for compatability info.

### Dev Sandbox

- Clone this repo
- Copy `./Sources/App/ServerConfig.swift.example` to `./Sources/App/ServerConfig.swift`
- Update the values in `./Sources/App/ServerConfig.swift`
- Install & run Postgres
    - Recommendation: macOS [Postgres.app](https://postgresapp.com)
- Terminal: `swift run App migrate` to provision Postgres

#### Configure your IDE

Some popular choices include

- Xcode (see [xcodereleases.com](https://xcodereleases.com))
- Microsoft [Visual Studio Code](https://visualstudio.microsoft.com)
    - or try [VSCodium](https://github.com/VSCodium/vscodium?tab=readme-ov-file#downloadinstall) (MIT License)
    - Decide if the included `.vscode/extensions.json` recommendations are right for you

### Docker
- Install [Docker Engine](https://docs.docker.com/engine/install/)
- Read [Vapor Docs](https://docs.vapor.codes/deploy/docker/?h=docker+compose)

A typical first build and run:
- `docker compose run migrate`
- `docker compose run app`

## What Next
- Point your browser at `localhost:8080` (or your prod uri)
- Try downloading and using [RapidAPI](https://paw.cloud) with the included `RapidAPI.paw` file.
