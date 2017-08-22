package io.prometheus.wls.rest;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintStream;

/**
 * This servlet represents the 'landing page' for the wls-exporter.
 */
@WebServlet(value = "/")
public class MainServlet extends HttpServlet {
    private static final String PAGE_HEADER
          = "<!DOCTYPE html>\n" +
            "<html lang=\"en\">\n" +
            "<head>\n" +
            "    <meta charset=\"UTF-8\">\n" +
            "    <title>Weblogic Prometheus Exporter</title>\n" +
            "</head>\n" +
            "<body>";

    private static final String RELATIVE_LINK = "metrics";

    @Override
    public void init(ServletConfig servletConfig) throws ServletException {
        LiveConfiguration.init(servletConfig);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        LiveConfiguration.setServer(req.getServerName(), req.getServerPort());
        resp.getOutputStream().println(PAGE_HEADER);
        displayMetricsLink(req, resp.getOutputStream());
        displayForm(resp.getOutputStream());
        displayConfiguration(resp.getOutputStream());

        resp.getOutputStream().close();
    }

    private void displayMetricsLink(HttpServletRequest req, ServletOutputStream outputStream) throws IOException {
        outputStream.println("<h2>This is the Weblogic Prometheus Exporter.</h2>");
        outputStream.println("<p>The metrics are found at <a href=\"" + getMetricsLink(req) + "\">");
        outputStream.println(RELATIVE_LINK + "</a> relative to this location.");
        outputStream.println("</p>");
    }

    private String getMetricsLink(HttpServletRequest req) {
        if (req.getServletPath().startsWith("/"))
            return RELATIVE_LINK;
        else
            return req.getContextPath() + "/" + RELATIVE_LINK;
    }

    private void displayForm(ServletOutputStream outputStream) throws IOException {
        outputStream.println("<h2>Configuration</h2>");
        outputStream.println("<p>To change the configuration:</p>");
        outputStream.println("<form action=\"configure\" method=\"post\" enctype=\"multipart/form-data\">");
        outputStream.println("    <input type=\"radio\" name=\"effect\" value=\"append\" checked=\"checked\">Append");
        outputStream.println("    <input type=\"radio\" name=\"effect\" value=\"replace\">Replace");
        outputStream.println("    <br><input type=\"file\" name=\"configuration\">");
        outputStream.println("    <br><input type=\"submit\">");
        outputStream.println("</form>");
    }

    private void displayConfiguration(ServletOutputStream outputStream) throws IOException {
        try (PrintStream ps = new PrintStream(outputStream)) {
            ps.println("<p>Current Configuration</p>");
            ps.println("<p><code><pre>");
            ps.printf(LiveConfiguration.asString());
            ps.println("</pre></code></p>");
        }
    }
}