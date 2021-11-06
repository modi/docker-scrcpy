# Dockerized Scrcpy

X 权限：

    xhost + local:docker

运行：

    docker run --rm -it -u pilot --privileged -v /dev/bus/usb:/dev/bus/usb -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/modi/projects/docker-scrcpy/android-sdk-user-data:/home/pilot/.android -e DISPLAY=$DISPLAY modicn/scrcpy bash

adb connect x.x.x.x:y
scrcpy --max-size 1200
