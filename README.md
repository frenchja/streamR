streamR
=======

William Revelle often says that R can do anything, even order a pizza.  So, I wondered, could R be used to parse options and stream movies to my RTMP server using `ffmpeg`?

Installation
------------
```bash
sudo curl https://raw.githubusercontent.com/frenchja/streamR/master/stream.R -o /usr/local/bin/stream.R
sudo chmod +x /usr/local/bin/stream.R
```

Usage
-----
```bash
stream.R --server rtmp://yourserver movie.mkv
```

Options
-------

1. `--help`: Display help menu.
2. `--time`: Desired start time of stream.
3. `--server`: RTMP server address.
4. `--framerate`: Output framerate.
5. `--crf`: Constant Rate Factor.

TODO
----

1. Process management
2. Use lapply and cat to allow for the creation of a movie playlist.
