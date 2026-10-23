package com.trackandtrace.search;

import com.trackandtrace.search.dto.OrderSearchResultDto;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import jakarta.persistence.Query;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Service;

@Service
public class SearchService {
    @PersistenceContext
    private EntityManager entityManager;
    public List<OrderSearchResultDto> searchOrders(String ref, String status, Integer size, Integer page)
    {
        StringBuilder sql = new StringBuilder("select order_ref, order_type, customer_name, status, updated_at from V_ORDER_SEARCH where 1=1 ");

        if (ref != null && !ref.isEmpty()) {
            sql.append(" and order_ref like '%' || upper(:ref) || '%'");
        }

        if (status != null && !status.isEmpty()) {
            sql.append(" and status like '%' || upper(:status) || '%'");
        }

        sql.append(" OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY");

        //turn text into query obj
        Query query = entityManager.createNativeQuery(sql.toString());

        if (ref != null && !ref.isEmpty()) query.setParameter("ref", ref);
        if (status != null && !status.isEmpty()) query.setParameter("status", status);
        query.setParameter("offset", page * size);
        query.setParameter("size", size);

        List<Object[]> rows = query.getResultList();
        List<OrderSearchResultDto> results = new ArrayList<>();

        for (Object[] row : rows) {
            results.add(new OrderSearchResultDto(
                    (String) row[0],
                    (String) row[1],
                    (String) row[2],
                    (String) row[3],
                    row[4] != null ? ((java.sql.Timestamp) row[4]).toLocalDateTime() : null
            ));
        }
        return results;
    }

    public int countOrders(String ref, String status) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM V_ORDER_SEARCH WHERE 1=1");

        if (ref != null && !ref.isEmpty()) {
            sql.append(" AND UPPER(order_ref) LIKE '%' || UPPER(:ref) || '%'");
        }
        if (status != null && !status.isEmpty()) {
            sql.append(" AND UPPER(status) LIKE '%' || UPPER(:status) || '%'");
        }

        Query query = entityManager.createNativeQuery(sql.toString());
        if (ref != null && !ref.isEmpty()) query.setParameter("ref", ref);
        if (status != null && !status.isEmpty()) query.setParameter("status", status);

        return ((Number) query.getSingleResult()).intValue();
    }
}
