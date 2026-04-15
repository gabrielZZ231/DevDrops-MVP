// Caminho: src/main/java/br/com/devdrops/dao/DropDAO.java
package br.com.devdrops.dao;

import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.Query;

import br.com.devdrops.model.Drop;

public class DropDAO {

    public void salvar(Drop drop) {
        EntityManager em = JPAUtil.getEntityManager();

        try {
            em.getTransaction().begin();

            if (drop.getId() == null) {
                em.persist(drop);
            } else {
                em.merge(drop);
            }

            em.getTransaction().commit();
        } catch (RuntimeException e) {
            if (em.getTransaction() != null && em.getTransaction().isActive()) {
                em.getTransaction().rollback();
            }
            throw e;
        } finally {
            if (em != null && em.isOpen()) {
                em.close();
            }
        }
    }

    public List<Drop> listarTodos() {
        EntityManager em = JPAUtil.getEntityManager();

        try {
            Query query = em.createQuery("SELECT d FROM Drop d ORDER BY d.dataPublicacao DESC");
            @SuppressWarnings("unchecked")
            List<Drop> resultado = (List<Drop>) query.getResultList();
            return resultado;
        } finally {
            if (em != null && em.isOpen()) {
                em.close();
            }
        }
    }
}
