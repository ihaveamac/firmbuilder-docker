# firmbuilder-docker

A custom Docker image used to build Nintendo 3DS FIRM images. Based on the [devkitpro/devkitarm](https://hub.docker.com/r/devkitpro/devkitarm) image.

* GitHub repo: [ihaveamac/firmbuilder-docker](https://github.com/ihaveamac/firmbuilder-docker)
* Docker Hub: [ianburgwin/firmbuilder](https://hub.docker.com/r/ianburgwin/firmbuilder)

This includes:

* firmtool - used by most FIRMs like Luma3DS and GodMode9
* armips - used by GodMode9
* p7zip - used by GodMode9 to build release zips
* libctru (newer commits) - used by Luma3DS, which usually needs a newer libctru than the latest release

## Build

Prebuilt images can be pulled from [ianburgwin/firmbuilder](https://hub.docker.com/r/ianburgwin/firmbuilder). Or build it yourself:

```
docker build -t ianburgwin/firmbuilder .
```

## Usage

This adds a user and starts with the working directory `/host`.

```
docker run -it --rm -v $PWD:/host ianburgwin/firmbuilder
```
