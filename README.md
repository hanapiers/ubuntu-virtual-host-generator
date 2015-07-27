Ubuntu Virtual Host Generator 
==========================

A bash script that creates virtual host names for your projects that are under development.    

**Usage:**
```sh
./generate_virtual_host.sh -v example.com -w example_dir -l /path/to/logs/
Options:
-v: name of virtual host
-w: base directory or the document root
-l: logs directory (can be relative to -w)
-h: show usage
```

There is no need to run the file preceeded by `sudo` but it may ask you for root permission upon execution.

If you have different document root for your localhost, then change the value of `DOCUMENT_ROOT_PATH` on L8.
```sh
HOSTNAME_FILE="/etc/hosts"
VIRTUAL_HOSTNAME_PATH="/etc/apache2/sites-available/"
DOCUMENT_ROOT_PATH="$HOME/www/"
```

