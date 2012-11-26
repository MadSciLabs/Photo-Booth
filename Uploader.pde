  
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.protocol.HttpContext;

import java.io.*;
import java.awt.image.BufferedImage;
import java.awt.Graphics2D;
import javax.imageio.ImageIO;

HttpClient httpclient;


void setupPost(){
 
  ThreadSafeClientConnManager cm = new ThreadSafeClientConnManager();
  // Increase max total connection to 200
  cm.setMaxTotal(200);
  // Increase default max connection per route to 20
  cm.setDefaultMaxPerRoute(20);

  httpclient = new DefaultHttpClient(cm);
  httpclient.getParams().setParameter(CoreProtocolPNames.PROTOCOL_VERSION, HttpVersion.HTTP_1_1); 
}

Thread uploadImage(PImage img[], String id) {
  PostThread thread = new PostThread(img, id);
  thread.start();

  return thread;
}

// This method returns a buffered image with the contents of an image
public BufferedImage toBufferedImage(PImage pimg) {

  BufferedImage bimg = new BufferedImage(pimg.width, pimg.height, BufferedImage.TYPE_INT_ARGB_PRE);
  Graphics2D g2d = bimg.createGraphics();
  g2d.drawImage(pimg.getImage(), 0, 0, pimg.width, pimg.height, this);
  g2d.finalize();
  g2d.dispose();
  return bimg;
}

class PostThread extends Thread {
  PImage img[];
  String id;

  public PostThread(PImage img_[], String id_) {
    this.img = img_;
    this.id = id_;
  }

  private InputStreamKnownSizeBody pimageToFilePart(PImage img, String name) {
    try {
      ByteArrayOutputStream os = new ByteArrayOutputStream();
      ImageIO.write(toBufferedImage(img), "png", os);
      InputStream stream = new ByteArrayInputStream(os.toByteArray());
      return new InputStreamKnownSizeBody(stream, os.toByteArray().length, "image/png", name);
    } 
    catch (IOException e) {
      println("boohoo");
      return null;
    }
  }


  @Override
    void run() {
    println("thread running");

    HttpPost httppost = new HttpPost(url);
    MultipartEntity mpEntity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE);

    long now = millis();
    for(int i=0;i<img.length;i++){
      mpEntity.addPart("file"+ i, pimageToFilePart(img[i], now + ".png"));
    }

    try {
      mpEntity.addPart("event_id", new StringBody(eventId));
      mpEntity.addPart("location_id", new StringBody(locationId));
      mpEntity.addPart("rfid", new StringBody(id));
    } 
    catch (UnsupportedEncodingException e) {
    }


    httppost.setEntity(mpEntity);

    println("sending request");
    try {
      HttpResponse response = httpclient.execute(httppost);
      println(response.getStatusLine());
      wifiStatus = true;
    } 
    catch (IOException e) {
      println(e);
      wifiStatus = false;
    }
  }

  class InputStreamKnownSizeBody extends InputStreamBody {
    private int lenght;

    public InputStreamKnownSizeBody(
    final InputStream in, final int lenght, 
    final String mimeType, final String filename) {
      super(in, mimeType, filename);
      this.lenght = lenght;
    }

    @Override
      public long getContentLength() {
      return this.lenght;
    }
  }
}
