#!/bin/bash

# Dependencies
sudo apt-get update
sudo apt-get install -y git build-essential libusb-1.0-0-dev rtl-sdr librtlsdr-dev libortp-dev libsndfile1-dev libncurses5-dev libtecla1-dev libtinfo5 libtinfo-dev pkg-config libusb-1.0-0-dev libasound2-dev libpulse-dev libtool automake libfftw3-dev libltdl-dev libjack-jackd2-dev liborc-0.4-dev libuhd-dev libuhd003 libitpp-dev libcppunit-dev libboost-all-dev libboost-system-dev libboost-program-options-dev libboost-thread-dev libboost-regex-dev libgmp-dev libxi-dev libxmu-dev libqt5core5a libqt5gui5 libqt5widgets5 libqt5svg5-dev qttools5-dev qttools5-dev-tools libudev-dev

# OP25
git clone https://github.com/boatbod/op25.git
cd op25
./configure
make
sudo make install

# Darkice
sudo apt-get install -y darkice
sudo tee /etc/darkice.cfg > /dev/null <<EOF
[general]
duration        = 0
bufferSecs      = 5
reconnect       = yes
reconnectDelay  = 5

[input]
device          = pulse
sampleRate      = 44100
bitsPerSample   = 16
channel         = 2
samplerateConv  = none

[icecast2-0]
bitrateMode     = cbr
format          = mp3
bitrate         = 128
server          = <your broadcastify server>
port            = 80
password        = <your broadcastify password>
mountPoint      = <your mount point>
name            = <your stream name>
genre           = <your genre>
url             = <your website>
public          = yes
EOF

# RTL-SDR
sudo apt-get install -y rtl-sdr
rtl_test -t

# Create named pipe
mkfifo /tmp/p25audio

# OP25 service
sudo tee /etc/systemd/system/op25.service > /dev/null <<EOF
[Unit]
Description=OP25 Trunked P25 Decoder
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/op25 -S <your P25 system file> -g <your P25 system group> -2 -T trunk.tsv -V -U -A fastlane-verbose -o /tmp/p25audio
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable op25.service
sudo systemctl start op25.service

# Darkice service
sudo tee /etc/systemd/system/darkice.service > /dev/null <<EOF
[Unit]
Description=Darkice Audio Streaming Client
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/darkice -c /etc/darkice.cfg -R 2 -i /tmp/p25audio
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable darkice.service
sudo systemctl start darkice.service
