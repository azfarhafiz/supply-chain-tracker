package com.trackandtrace.orders;

import com.trackandtrace.orders.dto.CustomerOrderDto;
import com.trackandtrace.orders.dto.OrderEventDto;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;

@Service
public class CustomerOrderService {
    @PersistenceContext

    private EntityManager entityManager;

    public CustomerOrderDto getOrderByRef(String ref) {
        String sql = "select a.order_ref, b.name, a.status,a.order_date, a.requested_delivery_date, a.country_code, " +
                "a.total_items, a.total_weight_kg from customer_order  a " +
                "join customer b on a.customer_id = b.customer_id " +
                "where a.order_ref = :ref";

        Query query = entityManager.createNativeQuery(sql);
        query.setParameter("ref", ref);

        try {
            Object[] row = (Object[]) query.getSingleResult();

            return new CustomerOrderDto(
                    (String) row[0],
                    (String) row[1],
                    (String) row[2],
                    row[3] != null ? ((java.sql.Timestamp) row[3]).toLocalDateTime().toLocalDate() : null,
                    row[4] != null ? ((java.sql.Timestamp) row[4]).toLocalDateTime().toLocalDate() : null,
                    (String) row[5],
                    row[6] != null ? ((Number) row[6]).intValue() : null,
                    row[7] != null ? ((Number) row[7]).doubleValue() : null
                    );

        } catch (NoResultException e) {
            throw new IllegalArgumentException("Order not found: " + ref);
        }

    }

    public List<OrderEventDto> getEventsByOrderRef(String ref) {
        String sql = "SELECT event_code, event_description, event_timestamp, location " +
                "FROM order_event " +
                "WHERE order_ref = :ref " +
                "ORDER BY event_timestamp DESC";
        Query query = entityManager.createNativeQuery(sql);
        query.setParameter("ref", ref);

        List<Object[]> rows = query.getResultList();
        List<OrderEventDto> results = new ArrayList<>();

        for (Object[] row : rows) {
            results.add(new OrderEventDto(
                    (String) row[0],
                    (String) row[1],
                    row[2] != null ? ((java.sql.Timestamp) row[2]).toLocalDateTime() : null,
                    (String) row[3]
            ));
        }

        return results;
    }
}
