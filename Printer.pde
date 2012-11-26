/// PRINTER ////
import javax.print.*; 
import javax.print.attribute.*; 
import java.awt.image.BufferedImage;
import java.awt.Graphics2D;
import java.awt.Graphics;
import java.awt.print.*;
import javax.imageio.ImageIO;
import javax.print.attribute.standard.*;
import java.awt.geom.AffineTransform;



//to properly print image.  
public void printImg(BufferedImage image) {      
  PrinterJob pj = PrinterJob.getPrinterJob();  
  PrintRequestAttributeSet aset = new HashPrintRequestAttributeSet();  
  aset.add(OrientationRequested.PORTRAIT);
   
  PageFormat pf = pj.getPageFormat(aset);
  Paper pp = pf.getPaper();
  println(pp.getWidth() + "," + pp.getHeight());
  println(pp.getImageableWidth() + "," + pp.getImageableHeight());
  pp.setSize(4*72, 6*72);
  pp.setImageableArea(-5, 5, 4*72+10, 6*72+5);
  pf.setPaper(pp);
  pj.setPrintable(new Printer(image), pf);

  try {  
    pj.print();
  } 
  catch (PrinterException e) {  
    println(e);
  }
}

BufferedImage toBufferedImage(PGraphics pimg) {
  BufferedImage bimg = new BufferedImage(pimg.width, pimg.height, BufferedImage.TYPE_INT_ARGB_PRE);
  Graphics2D g2d = bimg.createGraphics();
  g2d.drawImage(pimg.getImage(), 0, 0, pimg.width, pimg.height, this);
  g2d.finalize();
  g2d.dispose();
  return bimg;
}

//This class perform the printing
private static class Printer implements Printable {
  private final BufferedImage image;

  public Printer(BufferedImage image) {
    this.image = image;
  }

  public int print(Graphics graphics, PageFormat pageFormat, int pageIndex) throws PrinterException {
    if (pageIndex >= 1) {
      return Printable.NO_SUCH_PAGE;
    }

    Graphics2D g2d = (Graphics2D) graphics;

    g2d.translate(0, 0);

    if (this.image != null) {
      double xScaleFactor = pageFormat.getWidth() / this.image.getWidth();
      double yScaleFactor = pageFormat.getHeight() / this.image.getHeight();
      
      double scale = Math.min(xScaleFactor, yScaleFactor);
      printImage(g2d, this.image, scale);

      return Printable.PAGE_EXISTS;
    } 
    else {
      return Printable.NO_SUCH_PAGE;
    }
  }

  public void printImage(Graphics2D g2d, BufferedImage image, double scale) {
    if ((image == null) || (g2d == null)) {
      return;
    }
    AffineTransform at = new AffineTransform();
    at.setToIdentity();
    g2d.scale(scale, scale);
    g2d.drawRenderedImage(image, at);
  }
}
