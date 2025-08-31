#! /bin/bash
bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"
# creating "dictionary" to replace char with bar
i=0
while [ $i -lt ${#bar} ]
do
dict="${dict}s/$i/${bar:$i:1}/g;"
i=$((i=i+1))
done
# write cava config
config_file="/tmp/polybar_cava_config"
echo "
[general]
framerate = 60
autosens = 1
sensitivity = 120
bars = 18
bar_width = 1
bar_spacing = 0
lower_cutoff_freq = 50
higher_cutoff_freq = 20000
sleep_timer = 0

[input]
method = pulse
source = auto
sample_rate = 48000
sample_bits = 32
channels = 2

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
channels = stereo
mono_option = average
reverse = 0
bar_delimiter = 59
frame_delimiter = 10

[color]
gradient = 1
gradient_color_1 = '#94e2d5'
gradient_color_2 = '#89dceb'
gradient_color_3 = '#74c7ec'
gradient_color_4 = '#89b4fa'
gradient_color_5 = '#cba6f7'
gradient_color_6 = '#f5c2e7'
gradient_color_7 = '#eba0ac'
gradient_color_8 = '#f38ba8'

[smoothing]
monstercat = 1
waves = 0
noise_reduction = 50

[eq]
1 = 1.5
2 = 1.5
3 = 1
4 = 1
5 = 1
" > $config_file
# read stdout from cava
cava -p $config_file | while read -r line; do
echo $line | sed $dict
done