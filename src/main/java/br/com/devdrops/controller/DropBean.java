// Caminho: src/main/java/br/com/devdrops/controller/DropBean.java
package br.com.devdrops.controller;

import java.io.Serializable;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import br.com.devdrops.dao.DropDAO;
import br.com.devdrops.model.Drop;

public class DropBean implements Serializable {

    private static final long serialVersionUID = 1L;

    private Drop drop = new Drop();
    private List<Drop> drops;

    private final DropDAO dropDAO = new DropDAO();

    public DropBean() {
    }

    public String salvar() {
        if (drop.getDataPublicacao() == null) {
            drop.setDataPublicacao(new Date());
        }

        try {
            dropDAO.salvar(drop);
            FacesContext.getCurrentInstance().addMessage(null,
                    new FacesMessage(FacesMessage.SEVERITY_INFO, "Drop publicado com sucesso!", null));

            drop = new Drop();
            drops = null;
            return null;
        } catch (RuntimeException ex) {
            FacesContext.getCurrentInstance().addMessage(null,
                    new FacesMessage(FacesMessage.SEVERITY_ERROR,
                            "Nao foi possivel publicar. Verifique a conexao com o banco (DevDropsDS).", null));
            return null;
        }
    }

    public Drop getDrop() {
        return drop;
    }

    public void setDrop(Drop drop) {
        this.drop = drop;
    }

    public List<Drop> getDrops() {
        if (drops == null) {
            try {
                drops = dropDAO.listarTodos();
            } catch (RuntimeException ex) {
                FacesContext.getCurrentInstance().addMessage(null,
                        new FacesMessage(FacesMessage.SEVERITY_ERROR,
                                "Nao foi possivel carregar os drops. Verifique DEV_DROPS_DB_* no .env e o Postgres.",
                                null));
                drops = Collections.emptyList();
            }
        }
        return drops;
    }
}
