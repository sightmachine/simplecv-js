from gevent import monkey; monkey.patch_all()
from flask import Flask, request, send_file

from socketio import socketio_manage
from socketio.namespace import BaseNamespace

from SimpleCV import Image
from PIL import Image as PILImage
import os, re
import cStringIO as StringIO


class SimpleCVNamespace(BaseNamespace):
    def on_image(self, data):
        print 'Image Received'
        imgstr = re.search(r'base64,(.*)', data).group(1) #This is a hack to clean up the encoding.
        tempimg = StringIO.StringIO(imgstr.decode('base64'))
        pilimg = PILImage.open(tempimg)
        img = Image(pilimg)
        img = img.edges()
        pimg = img.getPIL()
        output = StringIO.StringIO()
        pimg.save(output, format='JPEG')
        sendstr = 'data:image/jpeg;base64,' + output.getvalue().encode('base64')
        self.emit('update', sendstr)

# Flask routes
app = Flask(__name__)
@app.route('/')
def index():
    return send_file('static/index.html')

@app.route("/socket.io/<path:path>")
def run_socketio(path):
    socketio_manage(request.environ, {'': SimpleCVNamespace})

if __name__ == '__main__':
    print 'Listening on http://localhost:8081'
    app.debug = True
    from werkzeug.wsgi import SharedDataMiddleware
    app = SharedDataMiddleware(app, {
        '/': os.path.join(os.path.dirname(__file__), 'static')
        })
    from socketio.server import SocketIOServer
    SocketIOServer(('0.0.0.0', 8081), app,
        namespace="socket.io", policy_server=False).serve_forever()
    
