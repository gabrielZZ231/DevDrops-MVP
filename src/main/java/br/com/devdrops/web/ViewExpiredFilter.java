// Caminho: src/main/java/br/com/devdrops/web/ViewExpiredFilter.java
package br.com.devdrops.web;

import java.io.IOException;

import javax.faces.application.ViewExpiredException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class ViewExpiredFilter implements Filter {

    public void init(FilterConfig filterConfig) throws ServletException {
        // no-op
    }

    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        try {
            chain.doFilter(request, response);
        } catch (Throwable t) {
            Throwable root = unwrap(t);
            if (request instanceof HttpServletRequest && response instanceof HttpServletResponse) {
                HttpServletRequest httpReq = (HttpServletRequest) request;
                HttpServletResponse httpResp = (HttpServletResponse) response;

                if (shouldHandle(httpReq, root)) {
                    handle(httpReq, httpResp);
                    return;
                }
            }

            if (t instanceof ServletException) {
                throw (ServletException) t;
            }
            if (t instanceof IOException) {
                throw (IOException) t;
            }
            if (t instanceof RuntimeException) {
                throw (RuntimeException) t;
            }
            throw new ServletException(t);
        }
    }

    public void destroy() {
        // no-op
    }

    private void handle(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (resp.isCommitted()) {
            // Can't redirect anymore.
            return;
        }

        String query = req.getQueryString();
        if (query != null && query.contains("ve=1")) {
            // Avoid redirect loops.
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "View expired");
            return;
        }

        HttpSession session = req.getSession(false);
        if (session != null) {
            try {
                session.invalidate();
            } catch (IllegalStateException ignore) {
                // already invalid
            }
        }

        String target = req.getContextPath() + "/index.xhtml?ve=1";
        resp.sendRedirect(target);
    }

    private boolean shouldHandle(HttpServletRequest req, Throwable root) {
        if (root instanceof ViewExpiredException) {
            return true;
        }

        // Mojarra 1.2 pode lançar StringIndexOutOfBoundsException ao tentar parsear
        // um javax.faces.ViewState inválido/expirado em RESTORE_VIEW.
        String viewState = req.getParameter("javax.faces.ViewState");
        if (viewState != null && root instanceof StringIndexOutOfBoundsException) {
            StackTraceElement[] st = root.getStackTrace();
            if (st != null) {
                for (int i = 0; i < st.length; i++) {
                    String cn = st[i].getClassName();
                    if (cn != null && cn.startsWith("com.sun.faces.application.StateManagerImpl")) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    private Throwable unwrap(Throwable t) {
        Throwable result = t;
        while (true) {
            Throwable cause = result.getCause();
            if (cause == null || cause == result) {
                return result;
            }
            result = cause;
        }
    }
}
