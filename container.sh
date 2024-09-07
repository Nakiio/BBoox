

CUSTOM_INIT=$1
FOLDER=$3
GRAPH=$2
NOGRAPHIC=""
DISK_SIZE="10G"

if [ -z "$CUSTOM_INIT" ] || [ -z "$GRAPH" ]; then
    echo "./container.sh custom_init graph"
    exit 1
fi

if [ -e "tmp" ]; then
    rm -r tmp
fi

if [ "$GRAPH" = false ]; then
    NOGRAPHIC="-nographic"
fi

mkdir tmp
echo "[ + ] Folder ./tmp created!"

mkdir ./tmp/share
echo "[ + ] Folder ./tmp/share created!"

echo "Hard disk at ./tmp/disk.img creating..."
qemu-img create -f raw ./tmp/disk.img $DISK_SIZE > /dev/null 2>&1
echo "[ + ] Hard disk at ./tmp/disk.img created!"

cp $CUSTOM_INIT ./tmp/share
echo "[ + ] File $CUSTOM_INIT copied at ./tmp/share!"

if [ -n "$FOLDER" ]; then
    cp -r $FOLDER ./tmp/share
    echo "[ + ] Folder $FOLDER copied at ./tmp/share!"
fi

echo "Vm Stating..."
qemu-system-x86_64 -m 400 $NOGRAPHIC -kernel ./assets/vmlinuz-linux -initrd ./assets/init.img -drive file=./tmp/disk.img,format=raw -virtfs local,path=./tmp/share,mount_tag=share,security_model=mapped-xattr,id=host0 > /dev/null 2>&1 &

echo "Server creating..."
tee ./tmp/server.py > /dev/null <<EOF

from http.server import BaseHTTPRequestHandler, HTTPServer

class MyHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        print(post_data.decode('utf-8'))

def run():
    server_address = ('', 8000)
    httpd = HTTPServer(server_address, MyHandler)
    print(f'==> Server Started on port {server_address[1]}')
    httpd.serve_forever()

if __name__ == '__main__':
    run()

EOF
echo "[ + ] Server created at ./tmp/server.py!"

python3 ./tmp/server.py

rm -r tmp