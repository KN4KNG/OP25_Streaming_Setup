# OP25_Streaming_Setup
#Setup script for using OP25, Darkice, and RTL-SDR to stream Trunked P25 Channels to Broadcastify on a Debian-based computer using a FIFO.

## Dependencies

Before we can begin, we need to install some dependencies. Open a terminal window and enter the following commands:
    
    sudo apt-get update sudo apt-get install git build-essential libusb-1.0-0-dev rtl-sdr librtlsdr-dev libortp-dev libsndfile1-dev libncurses5-dev libtecla1-dev libtinfo5 libtinfo-dev pkg-config libusb-1.0-0-dev libasound2-dev libpulse-dev libtool automake libfftw3-dev libltdl-dev libjack-jackd2-dev liborc-0.4-dev libuhd-dev libuhd003 libitpp-dev libcppunit-dev libboost-all-dev libboost-system-dev libboost-program-options-dev libboost-thread-dev libboost-regex-dev libgmp-dev libxi-dev libxmu-dev libqt5core5a libqt5gui5 libqt5widgets5 libqt5svg5-dev qttools5-dev qttools5-dev-tools libudev-dev 

## OP25

We'll start by cloning the OP25 repository:
    
    git clone https://github.com/boatbod/op25.git 

Next, we'll compile and install OP25:
    
    cd op25 ./configure make sudo make install 

## Darkice

We'll use Darkice to stream the audio to Broadcastify. Install Darkice using the following command:
    
    sudo apt-get install darkice 

Configure Darkice by creating a new file at /etc/darkice.cfg and pasting the following configuration:
    
    [general] 
    duration = 0 
    bufferSecs = 5 
    reconnect = yes 
    reconnectDelay = 5 
    
    [input] device = pulse 
    sampleRate = 44100 
    bitsPerSample = 16 
    channel = 2 
    samplerateConv = none 
    
    [icecast2-0] 
    bitrateMode = cbr 
    format = mp3 
    bitrate = 128 
    server = <your broadcastify server> 
    port = 80 
    password = <your broadcastify password> 
    mountPoint = <your mount point> 
    name = <your stream name> 
    genre = <your genre> 
    url = <your website> 
    public = yes 

Replace the placeholders with your actual values.

## RTL-SDR

Install RTL-SDR using the following command:
    
    sudo apt-get install rtl-sdr 

Test the RTL-SDR by running the following command:
    
    rtl_test -t 

## Starting the Stream

We're now ready to start the stream. First, create a named pipe by running the following command:
    
    mkfifo /tmp/p25audio 

Next, start OP25 using the following command:
    
    sudo op25 -S <your P25 system file> -g <your P25 system group> -2 -T trunk.tsv -V -U -A fastlane-verbose -o /tmp/p25audio 

Replace the placeholders with your actual values.

The `-o` option tells OP25 to output the decoded audio to the named pipe.

Finally, start Darkice and configure it to read from the named pipe:
    
    sudo darkice -c /etc/darkice.cfg -R 2 -i /tmp/p25audio 

The `-i` option tells Darkice to read

Once you are sure everything is working begin to create your services. With services OP25 and Darkice  are to run automatically on startup, and to restart automatically if they fail.

## OP25 Service

1. Create a new service file by running the following command:
    
    bash
    
    sudo nano /etc/systemd/system/op25.service 

2. Paste the following content into the file:
    
    makefile
    
    [Unit] Description=OP25 Trunked P25 Decoder After=network.target [Service] Type=simple ExecStart=/usr/local/bin/op25 -S <your P25 system file> -g <your P25 system group> -2 -T trunk.tsv -V -U -A fastlane-verbose -o /tmp/p25audio Restart=always RestartSec=10 User=root [Install] WantedBy=multi-user.target 

Replace the placeholders with your actual values.
3. Save the file and exit the text editor.
4. Reload the Systemd configuration by running the following command:
    
    sudo systemctl daemon-reload 

5. Start the OP25 service by running the following command:
    
    sql
    
    sudo systemctl start op25 

You can check the status of the service by running:
    
    lua
    
    sudo systemctl status op25 

## Darkice Service

1. Create a new service file by running the following command:
    
    bash
    
    sudo nano /etc/systemd/system/darkice.service 

2. Paste the following content into the file:
    
    makefile
    
    [Unit] Description=Darkice Audio Streaming Client After=network.target [Service] Type=simple ExecStart=/usr/bin/darkice -c /etc/darkice.cfg -R 2 -i /tmp/p25audio Restart=always RestartSec=10 User=root [Install] WantedBy=multi-user.target 

3. Save the file and exit the text editor.
4. Reload the Systemd configuration by running the following command:
    
    sudo systemctl daemon-reload 

5. Start the Darkice service by running the following command:
   
    sudo systemctl start darkice 

You can check the status of the service by running:
       
    sudo systemctl status darkice 
